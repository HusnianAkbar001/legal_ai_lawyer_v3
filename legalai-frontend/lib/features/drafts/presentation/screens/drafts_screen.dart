import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/file_download.dart';
import '../../domain/models/draft_model.dart';
import '../../data/datasources/drafts_remote_data_source.dart';
import 'template_selection_screen.dart';
import '../../../../core/layout/app_responsive.dart';

part 'drafts_screen.g.dart';

@riverpod
Future<List<Draft>> drafts(Ref ref) {
  return ref.watch(draftsRepositoryProvider).getDrafts();
}

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final draftsAsync = ref.watch(draftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDrafts),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: draftsAsync.when(
        data: (drafts) => drafts.isEmpty
            ? Center(child: Text(l10n.noDrafts))
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: drafts.length,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: AppResponsive.spacing(context, 44),
                        height: AppResponsive.spacing(context, 44),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_outlined, color: AppPalette.primary),
                      ),
                      title: Text(draft.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${l10n.createdLabel}: ${draft.createdAt.toIso8601String().split('T').first}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, color: AppPalette.info),
                            onPressed: () {
                              _showExportOptions(context, ref, draft);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppPalette.error),
                            onPressed: () {
                              _deleteDraft(context, ref, draft.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DraftDetailScreen(draft: draft)));
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()),
          );
        },
        label: Text(l10n.newDraft),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref, Draft draft) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(l10n.exportTxt),
              onTap: () async {
                Navigator.pop(context);
                await _exportTxt(context, ref, draft);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.exportPdf),
              onTap: () async {
                Navigator.pop(context);
                await _exportBinary(context, ref, draft, 'pdf', 'application/pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.exportDocx),
              onTap: () async {
                Navigator.pop(context);
                await _exportBinary(context, ref, draft, 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTxt(BuildContext context, WidgetRef ref, Draft draft) async {
    try {
      final text = await ref.read(draftsRepositoryProvider).exportDraftTxt(draft.id);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _TextPreviewScreen(title: draft.title, text: text)),
        );
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _exportBinary(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    String format,
    String mimeType,
  ) async {
    try {
      List<int> bytes;
      if (format == 'pdf') {
        bytes = await ref.read(draftsRepositoryProvider).exportDraftPdf(draft.id);
      } else {
        bytes = await ref.read(draftsRepositoryProvider).exportDraftDocx(draft.id);
      }
      final filename = '${draft.title}.$format';
      final path = await saveFile(Uint8List.fromList(bytes), filename, mimeType);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = path == null ? l10n.exportCanceled : l10n.savedFile(filename);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteDraft(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDraft),
        content: Text(l10n.deleteDraftConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(draftsRepositoryProvider).deleteDraft(id);
      ref.invalidate(draftsProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

class DraftDetailScreen extends StatelessWidget {
  final Draft draft;
  const DraftDetailScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(draft.title)),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
            child: SelectableText(draft.contentText ?? l10n.noContentAvailable),
          ),
        ),
      ),
    );
  }
}

class _TextPreviewScreen extends StatelessWidget {
  final String title;
  final String text;
  const _TextPreviewScreen({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
            child: SelectableText(text),
          ),
        ),
      ),
    );
  }
}
