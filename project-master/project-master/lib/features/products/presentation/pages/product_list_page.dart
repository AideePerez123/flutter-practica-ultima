import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../movements/domain/entities/movement_type.dart';
import '../../../movements/presentation/pages/movement_form_page.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

/// Searchable, filterable list of inventory products.
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, this.embedded = false, this.initialSearch});

  /// When embedded in the home shell the page does not show its own app bar.
  final bool embedded;
  final String? initialSearch;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().setSearch(widget.initialSearch);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (code == null || !mounted) return;
    _searchController.text = code;
    await context.read<ProductProvider>().setSearch(code);

    if (!mounted) return;
    final product = context.read<ProductProvider>().products.length == 1
        ? context.read<ProductProvider>().products.first
        : null;
    if (product != null) {
      await _openDetail(product.id!);
    } else {
      AppFeedback.info(context, 'No se encontró un producto con el código $code');
    }
  }

  Future<void> _openDetail(int productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: productId)),
    );
  }

  Future<void> _openForm({Product? product}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();

    final body = provider.isLoading && provider.products.isEmpty
        ? const LoadingView(message: 'Cargando productos...')
        : provider.products.isEmpty
            ? EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Sin productos',
                message: provider.query.search?.isNotEmpty == true
                    ? 'No hay coincidencias para "${provider.query.search}".'
                    : 'Agrega tu primer producto para comenzar.',
                action: FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => provider.load(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return Dismissible(
                      key: ValueKey(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline),
                      ),
                      confirmDismiss: (_) => _confirmDeactivate(product),
                      onDismissed: (_) {
                        context.read<ProductProvider>().deactivate(product.id!);
                        AppFeedback.info(context, 'Producto desactivado');
                      },
                      child: ProductCard(
                        product: product,
                        categoryName: categories.nameOf(product.categoryId),
                        onTap: () => _openDetail(product.id!),
                        onLongPress: () => _showActions(product),
                      ),
                    );
                  },
                ),
              );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Productos'),
              actions: [
                IconButton(
                  tooltip: 'Filtrar',
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o código',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) =>
                        context.read<ProductProvider>().setSearch(value),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<ProductProvider>().setSearch(null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Escanear código',
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
          ),
          _FilterBar(
            lowStockActive: provider.query.onlyLowStock,
            categoryId: provider.query.categoryId,
            onToggleLowStock: () =>
                context.read<ProductProvider>().toggleOnlyLowStock(),
            onCategoryChanged: (value) =>
                context.read<ProductProvider>().setCategory(value),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Producto'),
      ),
    );
  }

  Future<void> _showFilters() async {
    final provider = context.read<ProductProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo stock bajo'),
              value: provider.query.onlyLowStock,
              onChanged: (_) {
                context.read<ProductProvider>().toggleOnlyLowStock();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.read<ProductProvider>().resetFilters();
                _searchController.clear();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeactivate(Product product) async {
    final hasMovements =
        await context.read<ProductProvider>().findById(product.id!) != null;
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar producto'),
        content: Text(
          hasMovements
              ? 'El producto "${product.name}" tiene historial de movimientos. '
                  'Se desactivará y dejará de admitir movimientos, pero su '
                  'historial se conservará.'
              : '¿Deseas desactivar "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showActions(Product product) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Registrar entrada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovementFormPage(
                      args: MovementFormArgs(
                        type: MovementType.entrada,
                        productId: product.id,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Registrar salida'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovementFormPage(
                      args: MovementFormArgs(
                        type: MovementType.salida,
                        productId: product.id,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar producto'),
              onTap: () {
                Navigator.pop(context);
                _openForm(product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Ver etiquetas'),
              onTap: () {
                Navigator.pop(context);
                _openDetail(product.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.lowStockActive,
    required this.categoryId,
    required this.onToggleLowStock,
    required this.onCategoryChanged,
  });

  final bool lowStockActive;
  final int? categoryId;
  final VoidCallback onToggleLowStock;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('Stock bajo'),
            selected: lowStockActive,
            onSelected: (_) => onToggleLowStock(),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Todas'),
            selected: categoryId == null,
            onSelected: (_) => onCategoryChanged(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(category.name),
              selected: categoryId == category.id,
              onSelected: (_) => onCategoryChanged(category.id),
            ),
          ],
        ],
      ),
    );
  }
}
