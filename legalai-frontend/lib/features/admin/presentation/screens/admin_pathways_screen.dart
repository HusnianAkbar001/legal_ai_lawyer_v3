import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/domain/models/content_models.dart';
import '../../../content/presentation/controllers/content_controller.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminPathwaysProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(pathwaysProvider().future);
});

class AdminPathwaysScreen extends ConsumerWidget {
  const AdminPathwaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(adminPathwaysProvider);

    return AdminPage(
      title: 'Pathways',
      subtitle: 'Manage step-by-step legal guidance',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showPathwayForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Pathway'),
        ),
      ],
      body: pathwaysAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No pathways yet',
                message: 'Create structured guidance for users.',
                icon: Icons.account_tree_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pathway = items[index];
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
                      child: const Icon(Icons.account_tree_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pathway.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pathway.category} - ${pathway.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showPathwayForm(context, ref, pathway);
                        } else if (value == 'delete') {
                          await _deletePathway(context, ref, pathway.id);
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

  Future<void> _showPathwayForm(BuildContext context, WidgetRef ref, LegalPathway? pathway) async {
    final titleController = TextEditingController(text: pathway?.title ?? '');
    final summaryController = TextEditingController(text: pathway?.summary ?? '');
    final stepsController = TextEditingController(
      text: pathway == null ? '' : jsonEncode(pathway.steps.map((s) => s.toJson()).toList()),
    );
    final categoryController = TextEditingController(text: pathway?.category ?? '');
    final tagsController = TextEditingController(text: (pathway?.tags ?? []).join(', '));
    String language = pathway?.language ?? 'en';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(pathway == null ? 'Create Pathway' : 'Edit Pathway'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary')),
                const SizedBox(height: 8),
                TextField(
                  controller: stepsController,
                  decoration: const InputDecoration(labelText: 'Steps (JSON list)'),
                  maxLines: 6,
                ),
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

    if (titleController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title is required')),
        );
      }
      return;
    }

    List<dynamic> steps;
    try {
      final decoded = jsonDecode(stepsController.text.trim());
      if (decoded is! List) {
        throw const FormatException('Steps must be a list');
      }
      steps = decoded;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid steps JSON')),
        );
      }
      return;
    }

    try {
      final data = {
        'title': titleController.text.trim(),
        'summary': summaryController.text.trim().isEmpty ? null : summaryController.text.trim(),
        'steps': steps,
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (pathway == null) {
        await remote.createPathway(data);
      } else {
        await remote.updatePathway(pathway.id, data);
      }
      ref.invalidate(adminPathwaysProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deletePathway(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pathway'),
        content: const Text('Are you sure you want to delete this pathway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deletePathway(id);
      ref.invalidate(adminPathwaysProvider);
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
