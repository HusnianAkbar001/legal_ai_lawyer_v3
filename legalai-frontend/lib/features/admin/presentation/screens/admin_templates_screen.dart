import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/domain/models/content_models.dart';
import '../../../content/presentation/controllers/content_controller.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminTemplatesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(templatesProvider().future);
});

class AdminTemplatesScreen extends ConsumerWidget {
  const AdminTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(adminTemplatesProvider);

    return AdminPage(
      title: 'Templates',
      subtitle: 'Manage document templates',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showTemplateForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Template'),
        ),
      ],
      body: templatesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No templates yet',
                message: 'Create the first template for users.',
                icon: Icons.description_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = items[index];
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
                      child: const Icon(Icons.description_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${template.category} - ${template.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showTemplateForm(context, ref, template);
                        } else if (value == 'delete') {
                          await _deleteTemplate(context, ref, template.id);
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

  Future<void> _showTemplateForm(BuildContext context, WidgetRef ref, LegalTemplate? template) async {
    final titleController = TextEditingController(text: template?.title ?? '');
    final descController = TextEditingController(text: template?.description ?? '');
    final bodyController = TextEditingController(text: template?.body ?? '');
    final categoryController = TextEditingController(text: template?.category ?? '');
    final tagsController = TextEditingController(text: (template?.tags ?? []).join(', '));
    String language = template?.language ?? 'en';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(template == null ? 'Create Template' : 'Edit Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Body'), maxLines: 6),
                const SizedBox(height: 8),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 8),
                TextField(controller: tagsController, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                  ],
                  onChanged: (value) => setState(() => language = value ?? 'en'),
                ),
              ],
            ),
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
      if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Title and body are required')),
          );
        }
        return;
      }
      final data = {
        'title': titleController.text.trim(),
        'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
        'body': bodyController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (template == null) {
        await remote.createTemplate(data);
      } else {
        await remote.updateTemplate(template.id, data);
      }
      ref.invalidate(adminTemplatesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deleteTemplate(id);
      ref.invalidate(adminTemplatesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

