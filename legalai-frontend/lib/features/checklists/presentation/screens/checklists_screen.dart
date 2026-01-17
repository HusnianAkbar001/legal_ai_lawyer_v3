import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/checklist_models.dart';
import '../../data/datasources/checklists_remote_data_source.dart';
import '../../../../core/layout/app_responsive.dart';

part 'checklists_screen.g.dart';

@riverpod
Future<List<ChecklistCategory>> checklistCategories(Ref ref) {
  return ref.watch(checklistsRepositoryProvider).getCategories();
}

@riverpod
Future<List<ChecklistItem>> checklistItems(Ref ref, int categoryId) {
  return ref.watch(checklistsRepositoryProvider).getItems(categoryId);
}

class ChecklistsScreen extends ConsumerWidget {
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(checklistCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalChecklists)),
      body: categoriesAsync.when(
        data: (categories) => ListView.separated(
              padding: AppResponsive.pagePadding(context),
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: InkWell(
                    onTap: () => context.push(
                      '/checklists/${category.id}?title=${Uri.encodeComponent(category.title)}',
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                      child: Row(
                        children: [
                          Container(
                            width: AppResponsive.spacing(context, 48),
                            height: AppResponsive.spacing(context, 48),
                            decoration: BoxDecoration(
                              color: AppPalette.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.checklist_rtl_outlined, color: AppPalette.primary),
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: AppResponsive.spacing(context, 6)),
                                Text(
                                  l10n.tapToViewSteps,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppPalette.textSecondaryLight,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppPalette.textSecondaryLight),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }
}
