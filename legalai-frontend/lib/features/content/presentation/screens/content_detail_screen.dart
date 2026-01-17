import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/content_models.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';

class ContentDetailScreen extends ConsumerWidget {
  final String title;
  final String body;
  final String category;
  final List<String>? tags;
  final String? itemType;
  final int? itemId;

  const ContentDetailScreen({
    super.key,
    required this.title,
    required this.body,
    required this.category,
    this.tags,
    this.itemType,
    this.itemId,
  });

  factory ContentDetailScreen.fromRight(LegalRight right) {
    return ContentDetailScreen(
      title: right.topic,
      body: right.body,
      category: right.category,
      tags: right.tags,
      itemType: 'right',
      itemId: right.id,
    );
  }

  factory ContentDetailScreen.fromTemplate(LegalTemplate template) {
    return ContentDetailScreen(
      title: template.title,
      body: template.body, // In real app, this might show description first
      category: template.category,
      tags: template.tags,
      itemType: 'template',
      itemId: template.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    int? bookmarkId;
    if (itemType != null && itemId != null) {
      for (final bm in bookmarkItems) {
        if (bm['itemType'] == itemType && bm['itemId'] == itemId && bm['id'] is int) {
          bookmarkId = bm['id'] as int;
          break;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        actions: itemType != null && itemId != null
            ? [
                IconButton(
                  icon: Icon(
                    bookmarkId != null ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: () async {
                    await _toggleBookmark(
                      context,
                      ref,
                      itemType: itemType!,
                      itemId: itemId!,
                      bookmarkId: bookmarkId,
                    );
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            if (tags != null && tags!.isNotEmpty)
              Wrap(
                spacing: AppResponsive.spacing(context, 8),
                children: tags!.map((t) => Chip(label: Text(t), backgroundColor: AppPalette.backgroundLight)).toList(),
              ),
            SizedBox(height: AppResponsive.spacing(context, 24)),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _toggleBookmark(
  BuildContext context,
  WidgetRef ref, {
  required String itemType,
  required int itemId,
  required int? bookmarkId,
}) async {
  try {
    if (bookmarkId != null) {
      await ref.read(userRepositoryProvider).deleteBookmark(bookmarkId);
    } else {
      await ref.read(userRepositoryProvider).addBookmark(itemType, itemId);
    }
    ref.invalidate(userBookmarksProvider);
  } catch (e) {
    final err = ErrorMapper.from(e);
    final message = err is AppException ? err.userMessage : err.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
