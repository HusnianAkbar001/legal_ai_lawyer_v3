import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/layout/app_responsive.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  void _next(AppLocalizations l10n) {
    final pages = _pages(l10n);
    if (_index >= pages.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(appLanguageProvider);
    final pages = _pages(l10n);
    final isUrdu = language == 'ur';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1B22), Color(0xFF102A33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.spacing(context, 20),
                  AppResponsive.spacing(context, 12),
                  AppResponsive.spacing(context, 20),
                  0,
                ),
                child: Row(
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                        ButtonSegment(value: 'ur', label: Text(l10n.languageUrdu)),
                      ],
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppPalette.primary.withOpacity(0.2);
                          }
                          return Colors.white.withOpacity(0.06);
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white70;
                        }),
                        side: MaterialStateProperty.all(
                          BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                      ),
                      selected: {language},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) {
                        ref.read(appLanguageProvider.notifier).setLanguage(value.first);
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _complete,
                      child: Text(isUrdu ? l10n.skip : l10n.skip),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return _OnboardingPage(
                      data: page,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.spacing(context, 24),
                  AppResponsive.spacing(context, 6),
                  AppResponsive.spacing(context, 24),
                  AppResponsive.spacing(context, 24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 4)),
                          height: AppResponsive.spacing(context, 6),
                          width: i == _index ? AppResponsive.spacing(context, 36) : AppResponsive.spacing(context, 10),
                          decoration: BoxDecoration(
                            color: i == _index ? AppPalette.primary : Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 18)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 16)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _next(l10n),
                        child: Text(
                          _index == pages.length - 1 ? l10n.getStarted : l10n.next,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final features = data.features;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = AppResponsive.scale(context);
        final heightScale = _heightScale(constraints.maxHeight);
        final scale = widthScale < heightScale ? widthScale : heightScale;
        double s(double base) => base * scale;

        return Padding(
          padding: EdgeInsets.fromLTRB(s(20), s(8), s(20), s(12)),
          child: Column(
            children: [
              SizedBox(height: s(8)),
              Container(
                padding: EdgeInsets.all(s(18)),
                decoration: BoxDecoration(
                  color: const Color(0xFF132C35),
                  borderRadius: BorderRadius.circular(s(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: s(26),
                      offset: Offset(0, s(16)),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: s(96),
                    height: s(96),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.primary.withOpacity(0.12),
                      border: Border.all(color: AppPalette.primary.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(data.icon, size: s(42), color: AppPalette.primary),
                  ),
                ),
              ),
              SizedBox(height: s(16)),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: s(22),
                ),
              ),
              SizedBox(height: s(8)),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: s(14),
                ),
              ),
              if (features != null && features.isNotEmpty) ...[
                SizedBox(height: s(12)),
                Column(
                  children: features
                      .map(
                        (feature) => Padding(
                          padding: EdgeInsets.only(bottom: s(10)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: s(36),
                                height: s(36),
                                decoration: BoxDecoration(
                                  color: AppPalette.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(s(12)),
                                ),
                                child: Icon(feature.icon, color: AppPalette.primary, size: s(18)),
                              ),
                              SizedBox(width: s(10)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      feature.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: s(14),
                                      ),
                                    ),
                                    SizedBox(height: s(3)),
                                    Text(
                                      feature.subtitle,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: s(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingFeature {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_OnboardingFeature>? features;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.features,
  });
}

List<_OnboardingPageData> _pages(AppLocalizations l10n) {
  return [
    _OnboardingPageData(
      title: l10n.onboardingTitle1,
      subtitle: l10n.onboardingSubtitle1,
      icon: Icons.hub_outlined,
      features: [
        _OnboardingFeature(
          icon: Icons.gavel_outlined,
          title: l10n.onboardingFeatureLawyersTitle,
          subtitle: l10n.onboardingFeatureLawyersSubtitle,
        ),
        _OnboardingFeature(
          icon: Icons.notifications_active_outlined,
          title: l10n.onboardingFeatureRemindersTitle,
          subtitle: l10n.onboardingFeatureRemindersSubtitle,
        ),
        _OnboardingFeature(
          icon: Icons.checklist_rtl_outlined,
          title: l10n.onboardingFeatureChecklistsTitle,
          subtitle: l10n.onboardingFeatureChecklistsSubtitle,
        ),
      ],
    ),
    _OnboardingPageData(
      title: l10n.onboardingTitle2,
      subtitle: l10n.onboardingSubtitle2,
      icon: Icons.psychology_outlined,
    ),
    _OnboardingPageData(
      title: l10n.onboardingTitle3,
      subtitle: l10n.onboardingSubtitle3,
      icon: Icons.balance_outlined,
    ),
  ];
}

double _heightScale(double height) {
  if (height < 520) return 0.8;
  if (height < 600) return 0.88;
  if (height < 680) return 0.94;
  if (height < 760) return 0.98;
  return 1.0;
}
