import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/datasources/checklists_remote_data_source.dart';
import '../../domain/models/checklist_models.dart';
import '../../../../core/layout/app_responsive.dart';

final checklistItemsProvider =
    FutureProvider.family<List<ChecklistItem>, int>((ref, categoryId) {
  return ref.watch(checklistsRepositoryProvider).getItems(categoryId);
});

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String? categoryTitle;

  const ChecklistDetailScreen({
    super.key,
    required this.categoryId,
    this.categoryTitle,
  });

  @override
  ConsumerState<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(checklistItemsProvider(widget.categoryId));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle ?? l10n.checklist),
      ),
      body: itemsAsync.when(
        data: (items) => ListView.separated(
          padding: AppResponsive.pagePadding(context),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: CheckboxListTile(
                value: _checked.contains(item.id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _checked.add(item.id);
                    } else {
                      _checked.remove(item.id);
                    }
                  });
                },
                title: Text(item.text),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: item.required
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.spacing(context, 10),
                          vertical: AppResponsive.spacing(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.required,
                          style: TextStyle(fontSize: AppResponsive.font(context, 11), fontWeight: FontWeight.w600),
                        ),
                      )
                    : null,
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
