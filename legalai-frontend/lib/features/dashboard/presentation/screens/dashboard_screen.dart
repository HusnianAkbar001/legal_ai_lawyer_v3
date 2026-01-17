import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;
    ref.watch(contentSyncProvider);
    final name = user?.name ?? l10n.guestUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          const SafeModeBanner(),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          Container(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withOpacity(0.12),
                  AppPalette.secondary.withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppPalette.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeBack,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 6)),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/chat'),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.startChat),
                      ),
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 12)),
                    OutlinedButton(
                      onPressed: () => context.go('/browse'),
                      child: Text(l10n.browseLibrary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 24)),
          Text(
            l10n.quickActions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          Wrap(
            spacing: AppResponsive.spacing(context, 12),
            runSpacing: AppResponsive.spacing(context, 12),
            children: [
              _ActionTile(
                title: l10n.drafts,
                subtitle: l10n.draftsSubtitle,
                icon: Icons.edit_document,
                color: AppPalette.primary,
                onTap: () => context.push('/drafts'),
              ),
              _ActionTile(
                title: l10n.reminders,
                subtitle: l10n.remindersSubtitle,
                icon: Icons.notifications_active_outlined,
                color: AppPalette.warning,
                onTap: () => context.push('/reminders'),
              ),
              _ActionTile(
                title: l10n.bookmarks,
                subtitle: l10n.bookmarksSubtitle,
                icon: Icons.bookmarks_outlined,
                color: AppPalette.secondary,
                onTap: () => context.push('/bookmarks'),
              ),
              _ActionTile(
                title: l10n.lawyers,
                subtitle: l10n.lawyersSubtitle,
                icon: Icons.people_outline,
                color: AppPalette.info,
                onTap: () => context.go('/directory'),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 24)),
          _buildQuickActionCard(
            context,
            title: l10n.legalChecklists,
            icon: Icons.checklist_rtl_outlined,
            color: AppPalette.tertiary,
            onTap: () => context.go('/checklists'),
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _buildQuickActionCard(
            context,
            title: l10n.supportFeedback,
            icon: Icons.support_agent_outlined,
            color: AppPalette.primary,
            onTap: () => context.push('/support'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: AppResponsive.spacing(context, 24),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: AppResponsive.spacing(context, 16)),
              Text(
                title,
                style: TextStyle(fontSize: AppResponsive.font(context, 16), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: AppResponsive.font(context, 16), color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = width >= 900 ? 260.0 : (width - 52) / 2;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: tileWidth,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppResponsive.spacing(context, 40),
                  height: AppResponsive.spacing(context, 40),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppResponsive.spacing(context, 6)),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
