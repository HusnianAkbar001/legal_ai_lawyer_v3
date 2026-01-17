import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../checklists/data/datasources/checklists_remote_data_source.dart';
import '../../../checklists/domain/models/checklist_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminChecklistCategoriesProvider = FutureProvider.autoDispose<List<ChecklistCategory>>((ref) async {
  return ref.watch(checklistsRepositoryProvider).getCategories();
});

class AdminChecklistCategoriesScreen extends ConsumerWidget {
  const AdminChecklistCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminChecklistCategoriesProvider);

    return AdminPage(
      title: 'Checklists',
      subtitle: 'Manage checklist categories and items',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showCategoryForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Category'),
        ),
      ],
      body: categoriesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No categories yet',
                message: 'Create categories to group checklist items.',
                icon: Icons.checklist_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = items[index];
              return AdminCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.checklist_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ${category.order}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showCategoryForm(context, ref, category);
                        } else if (value == 'delete') {
                          await _deleteCategory(context, ref, category.id);
                        } else if (value == 'items') {
                          context.go('/admin/checklists/${category.id}?title=${Uri.encodeComponent(category.title)}');
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'items', child: Text('Manage Items')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _showCategoryForm(BuildContext context, WidgetRef ref, ChecklistCategory? category) async {
    final titleController = TextEditingController(text: category?.title ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    final orderController = TextEditingController(text: category?.order.toString() ?? '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Create Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon (optional)')),
            const SizedBox(height: 8),
            TextField(controller: orderController, decoration: const InputDecoration(labelText: 'Order'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;

    try {
      if (titleController.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Title is required')),
          );
        }
        return;
      }
      final order = int.tryParse(orderController.text.trim()) ?? 0;
      if (category == null) {
        await ref.read(checklistsRepositoryProvider).createCategory(
              title: titleController.text.trim(),
              icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
              order: order,
            );
      } else {
        await ref.read(checklistsRepositoryProvider).updateCategory(
              category.id,
              title: titleController.text.trim(),
              icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
              order: order,
            );
      }
      ref.invalidate(adminChecklistCategoriesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(checklistsRepositoryProvider).deleteCategory(id);
      ref.invalidate(adminChecklistCategoriesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

