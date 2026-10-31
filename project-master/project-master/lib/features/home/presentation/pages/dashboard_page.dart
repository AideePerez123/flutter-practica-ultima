import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../products/presentation/providers/product_provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../movements/domain/entities/movement_type.dart';
import '../../../movements/presentation/pages/movement_form_page.dart';
import '../../../movements/presentation/pages/movement_history_page.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../../products/presentation/pages/product_form_page.dart';
import '../../../products/presentation/pages/product_list_page.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../providers/dashboard_provider.dart';

/// Landing dashboard with aggregate indicators and quick actions.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<DashboardProvider>().load();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await _refresh();
  }

  Future<void> _scanProduct() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (code == null || !mounted) return;

    final product = await context.read<ProductProvider>().findByCode(code);
    if (!mounted) return;
    if (product == null) {
      AppFeedback.info(
        context,
        'Código leído: $code. No hay un producto registrado con ese código.',
      );
      return;
    }

    await _open(ProductDetailPage(productId: product.id!));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final stats = dashboard.stats;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Inteligente'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dashboard.isLoading && stats.totalProducts == 0
          ? const LoadingView(message: 'Calculando indicadores...')
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _SummaryCard(
                        label: 'Productos activos',
                        value: Formatters.integer(stats.activeProducts),
                        icon: Icons.inventory_2_outlined,
                        color: scheme.primary,
                      ),
                      _SummaryCard(
                        label: 'Stock bajo',
                        value: Formatters.integer(stats.lowStockCount),
                        icon: Icons.warning_amber_rounded,
                        color: scheme.error,
                      ),
                      _SummaryCard(
                        label: 'Movimientos',
                        value: Formatters.integer(stats.totalMovements),
                        icon: Icons.swap_vert,
                        color: scheme.tertiary,
                      ),
                      _SummaryCard(
                        label: 'Valor inventario',
                        value: Formatters.currency(stats.inventoryValue),
                        icon: Icons.account_balance_wallet_outlined,
                        color: scheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Acciones rápidas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        label: 'Escanear',
                        icon: Icons.qr_code_scanner,
                        onTap: _scanProduct,
                      ),
                      _QuickAction(
                        label: 'Producto',
                        icon: Icons.add_box_outlined,
                        onTap: () => _open(const ProductFormPage()),
                      ),
                      _QuickAction(
                        label: 'Entrada',
                        icon: Icons.arrow_downward,
                        onTap: () => _open(
                          const MovementFormPage(
                            args: MovementFormArgs(type: MovementType.entrada),
                          ),
                        ),
                      ),
                      _QuickAction(
                        label: 'Salida',
                        icon: Icons.arrow_upward,
                        onTap: () => _open(
                          const MovementFormPage(
                            args: MovementFormArgs(type: MovementType.salida),
                          ),
                        ),
                      ),
                      _QuickAction(
                        label: 'Historial',
                        icon: Icons.history,
                        onTap: () => _open(const MovementHistoryPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Productos con stock bajo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _open(const ProductListPage()),
                        child: const Text('Ver todo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (stats.lowStockProducts.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.verified_outlined),
                        title: Text(
                          'Todo el inventario está por encima del mínimo.',
                        ),
                      ),
                    )
                  else
                    ...stats.lowStockProducts.take(5).map(
                          (product) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.warning_amber_rounded),
                              title: Text(product.name),
                              subtitle: Text(
                                'Código ${product.code} · '
                                'stock ${product.currentStock}',
                              ),
                              trailing: StatusChip(
                                label: 'Mín. ${product.minStock}',
                                color: scheme.error,
                              ),
                              onTap: () =>
                                  _open(ProductListPage(initialSearch: product.code)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
