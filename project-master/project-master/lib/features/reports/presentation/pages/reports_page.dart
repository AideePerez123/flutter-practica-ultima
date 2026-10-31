import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../movements/presentation/providers/movement_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/services/csv_export_service.dart';

/// Report centre: KPI summary plus CSV exports and PDF label sheet.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _busy = false;

  Future<void> _exportProducts() async {
    await _run(() async {
      final products = context.read<ProductProvider>();
      final categories = context.read<CategoryProvider>();
      await products.load();
      final file = await const CsvExportService().exportProducts(
        products.products,
        categoryName: categories.nameOf,
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Inventario de productos'),
      );
    });
  }

  Future<void> _exportMovements() async {
    await _run(() async {
      final movements = context.read<MovementProvider>();
      await movements.load();
      final file =
          await const CsvExportService().exportMovements(movements.movements);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Historial de movimientos'),
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) AppFeedback.fromError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final movements = context.watch<MovementProvider>();

    final totalStock =
        products.products.fold<int>(0, (sum, p) => sum + p.currentStock);
    final totalValue =
        products.products.fold<double>(0, (sum, p) => sum + p.inventoryValue);
    final lowStock = products.products.where((p) => p.isLowStock).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: _busy
          ? const LoadingView(message: 'Generando archivo...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Resumen del inventario',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _ReportRow(
                        label: 'Productos registrados',
                        value: Formatters.integer(products.products.length),
                      ),
                      _ReportRow(
                        label: 'Unidades en existencia',
                        value: Formatters.integer(totalStock),
                      ),
                      _ReportRow(
                        label: 'Productos con stock bajo',
                        value: Formatters.integer(lowStock),
                      ),
                      _ReportRow(
                        label: 'Valor total del inventario',
                        value: Formatters.currency(totalValue),
                        emphasize: true,
                      ),
                      _ReportRow(
                        label: 'Movimientos registrados',
                        value: Formatters.integer(movements.movements.length),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Exportar datos',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _exportProducts,
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('Exportar productos (CSV)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _exportMovements,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Exportar movimientos (CSV)'),
                ),
              ],
            ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: emphasize
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
        ],
      ),
    );
  }
}
