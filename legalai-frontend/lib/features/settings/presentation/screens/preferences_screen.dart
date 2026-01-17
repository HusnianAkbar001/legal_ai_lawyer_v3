import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('preferences');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferences)),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          const SafeModeBanner(),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _Section(
            title: l10n.appearance,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.system)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.light)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value.first);
              },
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _Section(
            title: l10n.language,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'ur', label: Text(l10n.languageUrdu)),
              ],
              selected: {language},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                ref.read(appLanguageProvider.notifier).setLanguage(value.first);
              },
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 20)),
          Text(
            l10n.preferencesNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          child,
        ],
      ),
    );
  }
}
