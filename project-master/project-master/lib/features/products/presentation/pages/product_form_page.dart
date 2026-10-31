import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/error/domain_exception.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/product_validator.dart';
import '../providers/product_provider.dart';
import 'product_detail_page.dart';

/// Create or edit a product.
///
/// Stock is never edited from here; it is managed through movements. On
/// creation the initial quantity is recorded as an entry movement.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _saleController = TextEditingController();
  final _minStockController = TextEditingController();
  final _initialStockController = TextEditingController(text: '0');

  int? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _codeController.text = product.code;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _purchaseController.text = product.purchasePrice.toStringAsFixed(2);
      _saleController.text = product.salePrice.toStringAsFixed(2);
      _minStockController.text = product.minStock.toString();
      _categoryId = product.categoryId;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchaseController.dispose();
    _saleController.dispose();
    _minStockController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ProductProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    final product = Product(
      id: widget.product?.id,
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _categoryId,
      purchasePrice: double.tryParse(_purchaseController.text) ?? 0,
      salePrice: double.tryParse(_saleController.text) ?? 0,
      currentStock: widget.product?.currentStock ??
          (int.tryParse(_initialStockController.text) ?? 0),
      minStock: int.tryParse(_minStockController.text) ?? 0,
      active: widget.product?.active ?? true,
    );

    try {
      ProductValidator().validate(product);

      if (widget.isEditing) {
        await provider.updateProduct(product);
        if (!mounted) return;
        AppFeedback.success(context, 'Producto actualizado');
        Navigator.pop(context);
        return;
      }

      final created = await provider.createProduct(
        product,
        responsible: AppConstants.defaultResponsible,
      );
      await categoryProvider.load();
      if (!mounted) return;
      AppFeedback.success(context, 'Producto registrado');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: created!.id!),
        ),
      );
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
    final categories = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código único *',
                  helperText: 'Se usa para el código de barras y el QR',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El código es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'Usa al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...categories.categories.map(
                    (category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio compra',
                        prefixText: '\$ ',
                      ),
                      validator: (value) =>
                          _validateNumber(value, allowZero: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _saleController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio venta',
                        prefixText: '\$ ',
                      ),
                      validator: (value) => _validateNumber(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Valor no válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isEditing
                        ? TextFormField(
                            initialValue:
                                '${widget.product!.currentStock} unidades',
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Stock actual',
                              helperText: 'Solo cambia con movimientos',
                            ),
                          )
                        : TextFormField(
                            controller: _initialStockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock inicial',
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Valor no válido';
                              }
                              return null;
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(widget.isEditing ? 'Guardar cambios' : 'Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNumber(String? value, {bool allowZero = false}) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 'Valor no válido';
    if (!allowZero && parsed <= 0) return 'Debe ser mayor que cero';
    if (parsed < 0) return 'No puede ser negativo';
    return null;
  }
}
