import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../content/presentation/controllers/content_controller.dart';
import 'template_generate_screen.dart';
import '../../../../core/layout/app_responsive.dart';

class TemplateSelectionScreen extends ConsumerWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(templatesProvider());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectTemplate)),
      body: templatesAsync.when(
        data: (items) => ListView.separated(
          padding: AppResponsive.pagePadding(context),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.category),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TemplateGenerateScreen(template: item)),
                  );
                },
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
