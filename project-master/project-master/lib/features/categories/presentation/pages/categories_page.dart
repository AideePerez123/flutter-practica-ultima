import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/category_provider.dart';

/// Manage the product categories.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _edit(BuildContext context, {int? id, String? current}) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Nueva categoría' : 'Editar categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !context.mounted) return;
    final provider = context.read<CategoryProvider>();
    try {
      if (id == null) {
        await provider.create(name);
      } else {
        await provider.update(
          provider.categories.firstWhere((c) => c.id == id).copyWith(name: name),
        );
      }
      if (context.mounted) AppFeedback.success(context, 'Categoría guardada');
    } catch (e) {
      if (context.mounted) AppFeedback.fromError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          'Los productos de "$name" quedarán sin categoría. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<CategoryProvider>().delete(id);
    if (context.mounted) AppFeedback.info(context, 'Categoría eliminada');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: provider.categories.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'Sin categorías',
              message: 'Crea categorías para agrupar tus productos.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _edit(
                          context,
                          id: category.id,
                          current: category.name,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () =>
                            _delete(context, category.id!, category.name),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Categoría'),
      ),
    );
  }
}
