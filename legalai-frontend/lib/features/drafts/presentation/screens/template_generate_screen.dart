import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../content/domain/models/content_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/drafts_remote_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_palette.dart';
import 'drafts_screen.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../../core/layout/app_responsive.dart';

class TemplateGenerateScreen extends ConsumerStatefulWidget {
  final LegalTemplate template;
  const TemplateGenerateScreen({super.key, required this.template});

  @override
  ConsumerState<TemplateGenerateScreen> createState() => _TemplateGenerateScreenState();
}

class _TemplateGenerateScreenState extends ConsumerState<TemplateGenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  List<String> get _fields {
    final matches = RegExp(r'\{\{\s*([^\}]+)\s*\}\}').allMatches(widget.template.body);
    final names = matches.map((m) => m.group(1)?.trim() ?? '').where((e) => e.isNotEmpty).toSet();
    return names.toList();
  }

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final answers = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      answers[entry.key] = entry.value.text.trim();
    }

    setState(() => _submitting = true);
    try {
      final draft = await ref.read(draftsRepositoryProvider).generateDraft(
            widget.template.id,
            answers,
            user,
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DraftDetailScreen(draft: draft)),
        );
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = _fields;
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    int? bookmarkId;
    for (final bm in bookmarkItems) {
      if (bm['itemType'] == 'template' && bm['itemId'] == widget.template.id && bm['id'] is int) {
        bookmarkId = bm['id'] as int;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.title),
        actions: [
          IconButton(
            icon: Icon(bookmarkId != null ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              await _toggleBookmark(
                context,
                ref,
                itemId: widget.template.id,
                bookmarkId: bookmarkId,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.template.description.isNotEmpty) ...[
                Text(
                  widget.template.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppPalette.textSecondaryLight),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
              ],
              if (fields.isEmpty)
                Text(l10n.noFieldsDetected)
              else
                ...fields.map((field) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
                    child: TextFormField(
                      controller: _controllers[field],
                      decoration: InputDecoration(labelText: field),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.requiredField;
                        }
                        return null;
                      },
                    ),
                  );
                }),
              SizedBox(height: AppResponsive.spacing(context, 24)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.generateDraft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _toggleBookmark(
  BuildContext context,
  WidgetRef ref, {
  required int itemId,
  required int? bookmarkId,
}) async {
  try {
    if (bookmarkId != null) {
      await ref.read(userRepositoryProvider).deleteBookmark(bookmarkId);
    } else {
      await ref.read(userRepositoryProvider).addBookmark('template', itemId);
    }
    ref.invalidate(userBookmarksProvider);
  } catch (e) {
    final err = ErrorMapper.from(e);
    final message = err is AppException ? err.userMessage : err.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
