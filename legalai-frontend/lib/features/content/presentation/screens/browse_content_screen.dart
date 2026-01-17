import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../controllers/content_controller.dart';
import '../../domain/models/content_models.dart';
import 'content_detail_screen.dart';
import '../../../drafts/presentation/screens/template_generate_screen.dart';
import 'pathway_detail_screen.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';

class BrowseContentScreen extends ConsumerStatefulWidget {
  const BrowseContentScreen({super.key});

  @override
  ConsumerState<BrowseContentScreen> createState() => _BrowseContentScreenState();
}

class _BrowseContentScreenState extends ConsumerState<BrowseContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.legalLibrary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppPalette.primary,
          tabs: [
            Tab(text: l10n.rights, icon: const Icon(Icons.gavel)),
            Tab(text: l10n.templates, icon: const Icon(Icons.description)),
            Tab(text: l10n.pathways, icon: const Icon(Icons.timeline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RightsList(),
          TemplatesList(),
          PathwaysList(),
        ],
      ),
    );
  }
}

class RightsList extends ConsumerWidget {
  const RightsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rightsAsync = ref.watch(rightsProvider());
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkMap = <String, int>{};
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    for (final bm in bookmarkItems) {
      final type = bm['itemType'];
      final id = bm['itemId'];
      final bookmarkId = bm['id'];
      if (type is String && id is int && bookmarkId is int) {
        bookmarkMap['$type:$id'] = bookmarkId;
      }
    }

    return rightsAsync.when(
      data: (rights) => ListView.builder(
        padding: AppResponsive.pagePadding(context),
        itemCount: rights.length,
        itemBuilder: (context, index) {
          final right = rights[index];
          final key = 'right:${right.id}';
          final bookmarkId = bookmarkMap[key];
          return Card(
             margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
             child: ListTile(
               leading: const Icon(Icons.gavel, color: AppPalette.secondary),
               title: Text(right.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text(right.category),
               trailing: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     icon: Icon(
                       bookmarkId != null ? Icons.bookmark : Icons.bookmark_border,
                       color: AppPalette.primary,
                     ),
                     onPressed: () async {
                       await _toggleBookmark(
                         context,
                         ref,
                         itemType: 'right',
                         itemId: right.id,
                         bookmarkId: bookmarkId,
                       );
                     },
                   ),
                   const Icon(Icons.arrow_forward_ios, size: 16),
                 ],
               ),
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen.fromRight(right)));
               },
             ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(err.toString()))),
    );
  }
}

class TemplatesList extends ConsumerWidget {
  const TemplatesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(templatesProvider());
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkMap = <String, int>{};
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    for (final bm in bookmarkItems) {
      final type = bm['itemType'];
      final id = bm['itemId'];
      final bookmarkId = bm['id'];
      if (type is String && id is int && bookmarkId is int) {
        bookmarkMap['$type:$id'] = bookmarkId;
      }
    }

    return dataAsync.when(
      data: (items) => ListView.builder(
        padding: AppResponsive.pagePadding(context),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final key = 'template:${item.id}';
          final bookmarkId = bookmarkMap[key];
          return Card(
             margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
             child: ListTile(
               leading: const Icon(Icons.description, color: AppPalette.info),
               title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text(item.category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        bookmarkId != null ? Icons.bookmark : Icons.bookmark_border,
                        color: AppPalette.primary,
                      ),
                      onPressed: () async {
                        await _toggleBookmark(
                          context,
                          ref,
                          itemType: 'template',
                          itemId: item.id,
                          bookmarkId: bookmarkId,
                        );
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateGenerateScreen(template: item)));
               },
             ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(err.toString()))),
    );
  }
}

class PathwaysList extends ConsumerWidget {
  const PathwaysList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(pathwaysProvider());
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final bookmarkMap = <String, int>{};
    final bookmarkItems = bookmarksAsync.value ?? const <Map<String, dynamic>>[];
    for (final bm in bookmarkItems) {
      final type = bm['itemType'];
      final id = bm['itemId'];
      final bookmarkId = bm['id'];
      if (type is String && id is int && bookmarkId is int) {
        bookmarkMap['$type:$id'] = bookmarkId;
      }
    }

    return dataAsync.when(
      data: (items) => ListView.builder(
        padding: AppResponsive.pagePadding(context),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final key = 'pathway:${item.id}';
          final bookmarkId = bookmarkMap[key];
          return Card(
             margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
             child: ListTile(
               leading: const Icon(Icons.timeline, color: AppPalette.success),
               title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text(item.category),
               trailing: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     icon: Icon(
                       bookmarkId != null ? Icons.bookmark : Icons.bookmark_border,
                       color: AppPalette.primary,
                     ),
                     onPressed: () async {
                       await _toggleBookmark(
                         context,
                         ref,
                         itemType: 'pathway',
                         itemId: item.id,
                         bookmarkId: bookmarkId,
                       );
                     },
                   ),
                   const Icon(Icons.arrow_forward_ios, size: 16),
                 ],
               ),
               onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PathwayDetailScreen(pathway: item)));
               },
             ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(err.toString()))),
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
