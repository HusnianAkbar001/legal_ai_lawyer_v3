import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/layout/app_responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final onboardingComplete = ref.read(onboardingControllerProvider);
    if (!onboardingComplete) {
      context.go('/onboarding');
      return;
    }
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (user.isAdmin == true) {
      context.go('/admin/overview');
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(appLanguageProvider);
    final title = l10n.splashTitle;
    final subtitle = l10n.splashSubtitle;
    final initializing = l10n.initializing;
    final secure = l10n.securePrivate;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1B22), Color(0xFF0F2A33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: AppResponsive.spacing(context, 140),
                      height: AppResponsive.spacing(context, 140),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.primary.withOpacity(0.12),
                      ),
                    ),
                    Container(
                      width: AppResponsive.spacing(context, 92),
                      height: AppResponsive.spacing(context, 92),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0C2730),
                        border: Border.all(color: AppPalette.primary.withOpacity(0.6), width: 1.5),
                      ),
                      child: Icon(
                        Icons.balance_outlined,
                        size: AppResponsive.font(context, 44),
                        color: AppPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 28)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 34)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 64)),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: AppResponsive.spacing(context, 6),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primary),
                      borderRadius: BorderRadius.circular(999),
                    );
                  },
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 12)),
              Text(
                initializing,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.primary.withOpacity(0.9),
                    ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: Colors.white54),
                  SizedBox(width: AppResponsive.spacing(context, 8)),
                  Text(
                    secure,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  return Text(
                    'v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                  );
                },
              ),
              SizedBox(height: AppResponsive.spacing(context, 18)),
            ],
          ),
        ),
      ),
    );
  }
}
