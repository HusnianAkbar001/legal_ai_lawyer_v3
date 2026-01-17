import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/user_controller.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../controllers/activity_logger.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/presentation/screens/content_detail_screen.dart';
import '../../../content/presentation/screens/pathway_detail_screen.dart';
import '../../../drafts/presentation/screens/template_generate_screen.dart';
import '../../../../core/layout/app_responsive.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('bookmarks');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookmarks)),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return ListView(
              padding: AppResponsive.pagePadding(context),
              children: [
                const SafeModeBanner(),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Center(child: Text(l10n.noBookmarks)),
              ],
            );
          }
          return ListView.separated(
            padding: AppResponsive.pagePadding(context),
            itemCount: bookmarks.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SafeModeBanner();
              }
              final bm = bookmarks[index - 1];
              final type = bm['itemType']?.toString() ?? 'item';
              final itemId = bm['itemId'];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: AppResponsive.spacing(context, 44),
                    height: AppResponsive.spacing(context, 44),
                    decoration: BoxDecoration(
                      color: AppPalette.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bookmark, color: AppPalette.primary),
                  ),
                  title: Text(
                    _labelForType(l10n, type),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${l10n.idLabel}: ${itemId ?? '-'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await ref.read(userRepositoryProvider).deleteBookmark(bm['id'] as int);
                        await ref.read(userActivityLoggerProvider).logEvent(
                          'BOOKMARK_REMOVED',
                          payload: {
                            'itemType': type,
                            'itemId': itemId,
                          },
                        );
                        ref.invalidate(userBookmarksProvider);
                      } catch (e) {
                        final err = ErrorMapper.from(e);
                        final message = err is AppException ? err.userMessage : err.toString();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                  ),
                  onTap: () {
                    _openBookmark(context, ref, bm);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }

  Future<void> _openBookmark(BuildContext context, WidgetRef ref, Map<String, dynamic> bm) async {
    final type = bm['itemType']?.toString();
    final id = bm['itemId'];
    if (id is! int) return;

    try {
      final content = ref.read(contentRemoteDataSourceProvider);
      if (type == 'right') {
        final right = await content.getRight(id);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen.fromRight(right)));
        }
      } else if (type == 'template') {
        final template = await content.getTemplate(id);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateGenerateScreen(template: template)));
        }
      } else if (type == 'pathway') {
        final pathway = await content.getPathway(id);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PathwayDetailScreen(pathway: pathway)));
        }
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

String _labelForType(AppLocalizations l10n, String type) {
  switch (type) {
    case 'right':
      return l10n.legalRight;
    case 'template':
      return l10n.template;
    case 'pathway':
      return l10n.legalPathway;
    default:
      return l10n.savedItem;
  }
}
