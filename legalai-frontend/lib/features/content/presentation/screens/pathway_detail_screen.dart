import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../domain/models/content_models.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/layout/app_responsive.dart';

class PathwayDetailScreen extends ConsumerWidget {
  final LegalPathway pathway;
  const PathwayDetailScreen({super.key, required this.pathway});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    int? bookmarkId;
    for (final bm in bookmarkItems) {
      if (bm['itemType'] == 'pathway' && bm['itemId'] == pathway.id && bm['id'] is int) {
        bookmarkId = bm['id'] as int;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(pathway.title),
        actions: [
          IconButton(
            icon: Icon(bookmarkId != null ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              await _toggleBookmark(
                context,
                ref,
                itemId: pathway.id,
                bookmarkId: bookmarkId,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pathway.summary.isNotEmpty) ...[
              Text(
                pathway.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppPalette.textSecondaryLight),
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),
            ],
            ...pathway.steps.map((step) {
              return Card(
                margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
                child: Padding(
                  padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.stepWithTitle(step.step, step.title),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      Text(step.description),
                    ],
                  ),
                ),
              );
            }),
          ],
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
      await ref.read(userRepositoryProvider).addBookmark('pathway', itemId);
    }
    ref.invalidate(userBookmarksProvider);
  } catch (e) {
    final err = ErrorMapper.from(e);
    final message = err is AppException ? err.userMessage : err.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
