import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/error/domain_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/services/inventory_rules.dart';
import '../providers/movement_provider.dart';

/// Arguments controlling how the movement form opens.
class MovementFormArgs {
  const MovementFormArgs({
    this.type = MovementType.entrada,
    this.productId,
    this.initialCode,
  });

  final MovementType type;
  final int? productId;
  final String? initialCode;
}

/// Registers an inventory entry, exit or adjustment.
class MovementFormPage extends StatefulWidget {
  const MovementFormPage({super.key, this.args = const MovementFormArgs()});

  final MovementFormArgs args;

  @override
  State<MovementFormPage> createState() => _MovementFormPageState();
}

class _MovementFormPageState extends State<MovementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _responsibleController =
      TextEditingController(text: AppConstants.defaultResponsible);

  late MovementType _type;
  Product? _product;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _type = widget.args.type;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveInitialProduct());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialProduct() async {
    final provider = context.read<ProductProvider>();
    if (widget.args.productId != null) {
      final product = await provider.findById(widget.args.productId!);
      if (!mounted) return;
      setState(() => _product = product);
    } else if (widget.args.initialCode != null) {
      final product = await provider.findByCode(widget.args.initialCode!);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loadError = product == null
            ? 'No se encontró un producto con el código '
                '${widget.args.initialCode}.'
            : null;
      });
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (code == null || !mounted) return;
    final product = await context.read<ProductProvider>().findByCode(code);
    if (!mounted) return;
    setState(() {
      _product = product;
      _loadError = product == null
          ? 'No se encontró un producto con el código $code.'
          : null;
    });
  }

  Future<void> _pickProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ProductPickerSheet(),
    );
    if (product == null || !mounted) return;
    setState(() {
      _product = product;
      _loadError = null;
    });
  }

  Future<void> _submit() async {
    final product = _product;
    if (product == null) {
      AppFeedback.error(context, 'Selecciona un producto primero.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final quantity = int.parse(_quantityController.text);
    final reason = _reasonController.text.trim();
    final responsible = _responsibleController.text.trim();

    try {
      // Surface the resulting stock before persisting so the user sees the
      // effect of the operation.
      InventoryRules().computeResultingStock(
        type: _type,
        quantity: quantity,
        currentStock: product.currentStock,
        reason: reason,
      );

      final movement = Movement(
        productId: product.id!,
        type: _type,
        quantity: quantity,
        previousStock: product.currentStock,
        resultingStock: product.currentStock,
        reason: reason,
        responsible: responsible.isEmpty
            ? AppConstants.defaultResponsible
            : responsible,
        createdAt: DateTime.now(),
      );

      final movementProvider = context.read<MovementProvider>();
      final productProvider = context.read<ProductProvider>();
      await movementProvider.register(movement);
      await productProvider.load();
      if (!mounted) return;
      AppFeedback.success(
        context,
        '${_type.label} registrada para ${product.name}',
      );
      Navigator.pop(context, true);
    } on DomainException catch (e) {
      if (mounted) AppFeedback.error(context, e.message);
    } catch (e) {
      if (mounted) AppFeedback.fromError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      appBar: AppBar(title: Text('Registrar ${_type.label.toLowerCase()}')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<MovementType>(
                segments: const [
                  ButtonSegment(
                    value: MovementType.entrada,
                    icon: Icon(Icons.arrow_downward),
                    label: Text('Entrada'),
                  ),
                  ButtonSegment(
                    value: MovementType.salida,
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Salida'),
                  ),
                  ButtonSegment(
                    value: MovementType.ajuste,
                    icon: Icon(Icons.tune),
                    label: Text('Ajuste'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) =>
                    setState(() => _type = values.first),
              ),
              const SizedBox(height: 16),
              if (product == null)
                _ProductSelector(
                  error: _loadError,
                  onScan: _scan,
                  onPick: _pickProduct,
                )
              else
                _SelectedProduct(
                  product: product,
                  onClear: () => setState(() => _product = null),
                  onChange: _pickProduct,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type == MovementType.ajuste
                      ? 'Cantidad contada *'
                      : 'Cantidad *',
                  helperText: _type == MovementType.ajuste
                      ? 'Existencia real encontrada en el conteo'
                      : 'Unidades a ${_type == MovementType.entrada ? 'ingresar' : 'retirar'}',
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null) return 'Ingresa un número entero';
                  if (_type == MovementType.ajuste) {
                    return parsed < 0 ? 'No puede ser negativo' : null;
                  }
                  return parsed <= 0 ? 'Debe ser mayor que cero' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _type == MovementType.ajuste
                      ? 'Justificación *'
                      : 'Motivo *',
                  helperText: _type == MovementType.ajuste
                      ? 'Explica por qué difiere la existencia'
                      : 'Ej. compra a proveedor, venta de mostrador',
                  prefixIcon: const Icon(Icons.notes),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica el motivo del movimiento'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsibleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text('Registrar ${_type.label.toLowerCase()}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSelector extends StatelessWidget {
  const _ProductSelector({
    required this.error,
    required this.onScan,
    required this.onPick,
  });

  final String? error;
  final VoidCallback onScan;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: scheme.outline),
            const SizedBox(height: 8),
            Text(
              'Selecciona el producto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedProduct extends StatelessWidget {
  const _SelectedProduct({
    required this.product,
    required this.onClear,
    required this.onChange,
  });

  final Product product;
  final VoidCallback onClear;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text(product.name),
        subtitle: Text(
          '${product.code} · stock ${Formatters.integer(product.currentStock)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Cambiar',
              onPressed: onChange,
              icon: const Icon(Icons.swap_horiz),
            ),
            IconButton(
              tooltip: 'Quitar',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet();

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products.where((product) {
      if (_search.isEmpty) return true;
      final term = _search.toLowerCase();
      return product.name.toLowerCase().contains(term) ||
          product.code.toLowerCase().contains(term);
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.code} · stock ${product.currentStock}',
                  ),
                  enabled: product.active,
                  onTap: () => Navigator.pop(context, product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
