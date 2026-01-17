import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../checklists/data/datasources/checklists_remote_data_source.dart';
import '../../../checklists/domain/models/checklist_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminChecklistItemsProvider = FutureProvider.autoDispose.family<List<ChecklistItem>, int>((ref, categoryId) async {
  return ref.watch(checklistsRepositoryProvider).getItems(categoryId);
});

class AdminChecklistItemsScreen extends ConsumerWidget {
  final int categoryId;
  final String? categoryTitle;

  const AdminChecklistItemsScreen({
    super.key,
    required this.categoryId,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId <= 0) {
      return const AdminPage(
        title: 'Checklist Items',
        subtitle: 'Invalid category',
        body: Center(
          child: AdminEmptyState(
            title: 'Missing category',
            message: 'Select a checklist category to view its items.',
            icon: Icons.checklist_outlined,
          ),
        ),
      );
    }

    final itemsAsync = ref.watch(adminChecklistItemsProvider(categoryId));
    final title = categoryTitle?.isNotEmpty == true ? categoryTitle! : 'Checklist Items';

    return AdminPage(
      title: title,
      subtitle: 'Manage item ordering and requirements',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showItemForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Item'),
        ),
      ],
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No items yet',
                message: 'Add checklist items for this category.',
                icon: Icons.checklist_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
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
                            item.text,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ${item.order} - Required ${item.required}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showItemForm(context, ref, item);
                        } else if (value == 'delete') {
                          await _deleteItem(context, ref, item.id);
                        }
                      },
                      itemBuilder: (context) => const [
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

  Future<void> _showItemForm(BuildContext context, WidgetRef ref, ChecklistItem? item) async {
    final textController = TextEditingController(text: item?.text ?? '');
    final orderController = TextEditingController(text: item?.order.toString() ?? '0');
    bool requiredFlag = item?.required ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Create Item' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, decoration: const InputDecoration(labelText: 'Text')),
              const SizedBox(height: 8),
              TextField(controller: orderController, decoration: const InputDecoration(labelText: 'Order'), keyboardType: TextInputType.number),
              SwitchListTile(
                value: requiredFlag,
                title: const Text('Required'),
                onChanged: (value) => setState(() => requiredFlag = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      if (textController.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text is required')),
          );
        }
        return;
      }
      final order = int.tryParse(orderController.text.trim()) ?? 0;
      if (item == null) {
        await ref.read(checklistsRepositoryProvider).createItem(
              categoryId: categoryId,
              text: textController.text.trim(),
              required: requiredFlag,
              order: order,
            );
      } else {
        await ref.read(checklistsRepositoryProvider).updateItem(
              item.id,
              text: textController.text.trim(),
              required: requiredFlag,
              order: order,
              categoryId: categoryId,
            );
      }
      ref.invalidate(adminChecklistItemsProvider(categoryId));
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(checklistsRepositoryProvider).deleteItem(id);
      ref.invalidate(adminChecklistItemsProvider(categoryId));
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

