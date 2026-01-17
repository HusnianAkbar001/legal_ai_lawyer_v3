import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_stats_model.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

const int _maxUploadBytes = 30 * 1024 * 1024;
const List<String> _allowedExts = [
  'txt',
  'csv',
  'tsv',
  'json',
  'pdf',
  'docx',
  'xlsx',
  'png',
  'jpg',
  'jpeg',
  'svg',
];

class AdminKnowledgeScreen extends ConsumerWidget {
  const AdminKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(knowledgeSourcesProvider);

    return AdminPage(
      title: 'Knowledge Base',
      subtitle: 'Manage RAG sources and ingestion pipeline',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddSourceDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Source'),
        ),
      ],
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No sources yet',
                message: 'Add a URL or upload a file to start ingestion.',
                icon: Icons.auto_awesome_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final source = sources[index];
              final statusColor = source.status == 'done'
                  ? AdminColors.success
                  : source.status == 'failed'
                      ? AdminColors.error
                      : AdminColors.warning;
              return AdminCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        source.type == 'url' ? Icons.link : Icons.description_outlined,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${source.language} - ${source.status}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (source.status == 'failed')
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: AdminColors.primary,
                        onPressed: () => ref.read(adminActionsProvider.notifier).retrySource(source.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AdminColors.error,
                      onPressed: () => ref.read(adminActionsProvider.notifier).deleteSource(source.id),
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

  void _showAddSourceDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    String language = 'en';
    bool isUrl = true;
    PlatformFile? file;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Knowledge Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: isUrl,
                title: Text(isUrl ? 'URL Source' : 'File Upload'),
                onChanged: (value) => setState(() => isUrl = value),
              ),
              DropdownButtonFormField<String>(
                value: language,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                ],
                onChanged: (value) => setState(() => language = value ?? 'en'),
              ),
              const SizedBox(height: 8),
              if (isUrl) ...[
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
              ] else ...[
                TextButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: _allowedExts,
                      withData: kIsWeb,
                    );
                    if (result == null || result.files.isEmpty) {
                      return;
                    }
                    final selected = result.files.single;
                    final error = _validateKnowledgeFile(selected);
                    if (error != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      }
                      return;
                    }
                    setState(() => file = selected);
                  },
                  child: Text(file == null ? 'Select File' : 'Change File'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (isUrl) {
                  final title = titleController.text.trim();
                  final url = urlController.text.trim();
                  if (title.isEmpty || url.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title and URL are required')),
                      );
                    }
                    return;
                  }
                  if (!_isValidUrl(url)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid URL')),
                      );
                    }
                    return;
                  }
                  await ref.read(adminActionsProvider.notifier).ingestUrl(
                    title,
                    url,
                    language,
                  );
                } else {
                  if (file == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File is required')),
                      );
                    }
                    return;
                  }
                  final error = _validateKnowledgeFile(file!);
                  if (error != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                    }
                    return;
                  }
                  await ref.read(adminActionsProvider.notifier).uploadFile(file!, language);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Ingest'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String? _validateKnowledgeFile(PlatformFile file) {
  final ext = _fileExtension(file.name);
  if (ext.isEmpty || !_allowedExts.contains(ext)) {
    return 'File type not allowed';
  }
  if (file.size > _maxUploadBytes) {
    return 'File too large (max 30MB)';
  }
  if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
    return 'File data is missing';
  }
  return null;
}

bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return uri.host.isNotEmpty;
}
