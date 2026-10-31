import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/movement_repository.dart';
import '../../domain/entities/movement_type.dart';
import '../providers/movement_provider.dart';

/// Full movement history with filters by type and date range.
class MovementHistoryPage extends StatefulWidget {
  const MovementHistoryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MovementHistoryPage> createState() => _MovementHistoryPageState();
}

class _MovementHistoryPageState extends State<MovementHistoryPage> {
  MovementType? _type;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    await context.read<MovementProvider>().load(
          query: MovementQuery(
            type: _type,
            from: _range?.start,
            to: _range?.end,
          ),
        );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
    );
    if (range == null) return;
    setState(() => _range = range);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovementProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Movimientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MovementType?>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<MovementType?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      for (final type in MovementType.values)
                        DropdownMenuItem<MovementType?>(
                          value: type,
                          child: Text(type.label),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _type = value);
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Rango de fechas',
                  onPressed: _pickRange,
                  icon: Icon(
                    _range == null ? Icons.date_range : Icons.event_available,
                  ),
                ),
              ],
            ),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  StatusChip(
                    label:
                        '${Formatters.date(_range!.start)} - ${Formatters.date(_range!.end)}',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.date_range,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _range = null);
                      _reload();
                    },
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading && provider.movements.isEmpty
                ? const LoadingView(message: 'Cargando movimientos...')
                : provider.movements.isEmpty
                    ? const EmptyState(
                        icon: Icons.swap_vert,
                        title: 'Sin movimientos',
                        message: 'Las entradas y salidas aparecerán aquí.',
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: provider.movements.length,
                          itemBuilder: (context, index) {
                            return _MovementHistoryTile(
                              movement: provider.movements[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MovementHistoryTile extends StatelessWidget {
  const _MovementHistoryTile({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEntry = movement.delta > 0;
    final isAdjustment = movement.type == MovementType.ajuste;
    final color = isAdjustment
        ? scheme.tertiary
        : isEntry
            ? scheme.primary
            : scheme.error;
    final icon = isAdjustment
        ? Icons.tune
        : isEntry
            ? Icons.arrow_downward
            : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.productName ?? 'Producto',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    movement.productCode ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movement.reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.dateTime(movement.createdAt)} · '
                    '${movement.responsible}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(label: movement.type.label, color: color),
                const SizedBox(height: 6),
                Text(
                  '${movement.delta >= 0 ? '+' : ''}${movement.delta}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Stock ${movement.resultingStock}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
