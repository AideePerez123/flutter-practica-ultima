import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/code_preview.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../labels/presentation/pages/label_page.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../movements/domain/entities/movement_type.dart';
import '../../../movements/presentation/pages/movement_form_page.dart';
import '../../../movements/presentation/providers/movement_provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import 'product_form_page.dart';

/// Shows a product's data, its codes and its movement history.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  List<Movement> _movements = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = context.read<ProductProvider>();
    final movements = context.read<MovementProvider>();
    final product = await products.findById(widget.productId);
    final history = await movements.forProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _movements = history;
      _loading = false;
    });
  }

  Future<void> _registerMovement(MovementType type) async {
    final product = _product;
    if (product == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovementFormPage(
          args: MovementFormArgs(type: type, productId: product.id),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Producto no encontrado',
        ),
      );
    }

    final categoryName = context.read<CategoryProvider>().nameOf(product.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductFormPage(product: product),
                ),
              );
              await _load();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Etiquetas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LabelPage(product: product)),
            ),
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(product: product, categoryName: categoryName),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _registerMovement(MovementType.entrada),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Entrada'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _registerMovement(MovementType.salida),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Salida'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Códigos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  BarcodePreview(data: product.code),
                  const SizedBox(height: 16),
                  QrPreview(data: product.code, size: 160),
                  const SizedBox(height: 8),
                  Text(
                    'El código QR contiene únicamente el código del producto.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Historial de movimientos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${_movements.length} registros',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          if (_movements.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.history_toggle_off),
                title: Text('Sin movimientos registrados'),
              ),
            )
          else
            ..._movements.take(20).map((m) => _MovementTile(movement: m)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.product, required this.categoryName});

  final Product product;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.code,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.outline,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                if (!product.active)
                  StatusChip(
                    label: 'Inactivo',
                    color: scheme.outline,
                    icon: Icons.block,
                  )
                else if (product.isLowStock)
                  StatusChip(
                    label: 'Stock bajo',
                    color: scheme.error,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Formatters.integer(product.currentStock),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: product.isLowStock ? scheme.error : scheme.primary,
                  ),
            ),
            Text('unidades disponibles',
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 32),
            _Row(label: 'Categoría', value: categoryName),
            _Row(
              label: 'Precio compra',
              value: Formatters.currency(product.purchasePrice),
            ),
            _Row(
              label: 'Precio venta',
              value: Formatters.currency(product.salePrice),
            ),
            _Row(
              label: 'Margen',
              value: Formatters.currency(product.margin),
            ),
            _Row(label: 'Stock mínimo', value: '${product.minStock}'),
            _Row(
              label: 'Valor en inventario',
              value: Formatters.currency(product.inventoryValue),
            ),
            if (product.description.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEntry = movement.delta > 0;
    final color = isEntry ? scheme.primary : scheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isEntry ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text('${movement.type.label} · ${movement.delta.abs()} un.'),
        subtitle: Text(
          '${Formatters.dateTime(movement.createdAt)}\n${movement.reason}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${movement.resultingStock}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
