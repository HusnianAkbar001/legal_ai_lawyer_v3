import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/presentation/controllers/content_controller.dart';
import '../../../content/domain/models/content_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminRightsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(rightsProvider().future);
});

class AdminRightsScreen extends ConsumerWidget {
  const AdminRightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rightsAsync = ref.watch(adminRightsProvider);

    return AdminPage(
      title: 'Rights',
      subtitle: 'Manage legal rights library',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showRightForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Right'),
        ),
      ],
      body: rightsAsync.when(
        data: (rights) {
          if (rights.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No rights yet',
                message: 'Create the first right to populate the library.',
                icon: Icons.policy_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: rights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final right = rights[index];
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
                      child: const Icon(Icons.policy_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            right.topic,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${right.category} - ${right.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showRightForm(context, ref, right);
                        } else if (value == 'delete') {
                          await _deleteRight(context, ref, right.id);
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

  Future<void> _showRightForm(BuildContext context, WidgetRef ref, LegalRight? right) async {
    final topicController = TextEditingController(text: right?.topic ?? '');
    final bodyController = TextEditingController(text: right?.body ?? '');
    final categoryController = TextEditingController(text: right?.category ?? '');
    final tagsController = TextEditingController(text: (right?.tags ?? []).join(', '));
    String language = right?.language ?? 'en';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(right == null ? 'Create Right' : 'Edit Right'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: topicController, decoration: const InputDecoration(labelText: 'Topic')),
                const SizedBox(height: 8),
                TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Body'), maxLines: 5),
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
      if (topicController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic and body are required')),
          );
        }
        return;
      }
      final data = {
        'topic': topicController.text.trim(),
        'body': bodyController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (right == null) {
        await remote.createRight(data);
      } else {
        await remote.updateRight(right.id, data);
      }
      ref.invalidate(adminRightsProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteRight(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Right'),
        content: const Text('Are you sure you want to delete this right?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deleteRight(id);
      ref.invalidate(adminRightsProvider);
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

