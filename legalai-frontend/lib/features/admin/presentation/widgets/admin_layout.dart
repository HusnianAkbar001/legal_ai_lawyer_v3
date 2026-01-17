import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../theme/admin_theme.dart';

class AdminShellScreen extends ConsumerWidget {
  final Widget child;
  final String location;

  const AdminShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final useRail = size.width >= 960;
    final extendRail = size.width >= 1240;
    final items = _adminNavItems;
    final selectedIndex = _navIndexForLocation(location);

    return Theme(
      data: AdminTheme.dark,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AdminColors.background, Color(0xFF0F141C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const _BackgroundGlow(
              alignment: Alignment.topRight,
              color: AdminColors.primary,
              size: 420,
              opacity: 0.16,
            ),
            const _BackgroundGlow(
              alignment: Alignment.bottomLeft,
              color: AdminColors.accent,
              size: 360,
              opacity: 0.12,
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              drawer: useRail
                  ? null
                  : _AdminDrawer(
                      selectedIndex: selectedIndex,
                      onSelect: (index) {
                        Navigator.of(context).pop();
                        context.go(items[index].route);
                      },
                    ),
              body: SafeArea(
                child: Row(
                  children: [
                    if (useRail)
                      _AdminRail(
                        extended: extendRail,
                        selectedIndex: selectedIndex,
                        onSelect: (index) => context.go(items[index].route),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) => _AdminTopBar(
                              onMenu: useRail ? null : () => Scaffold.of(context).openDrawer(),
                              userName: ref.watch(authControllerProvider).value?.name ?? 'Admin',
                              onLogout: () => ref.read(authControllerProvider.notifier).logout(),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1240),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width >= 900 ? 28 : 18,
                                    vertical: 20,
                                  ),
                                  child: child,
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  const _BackgroundGlow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final bool expandBody;
  final Widget? header;

  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.expandBody = true,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AdminColors.textSecondary,
        );

    final headerWidget = header ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: subtitleStyle),
                  ],
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: actions!,
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerWidget,
        const SizedBox(height: 18),
        if (expandBody) Expanded(child: body) else body,
      ],
    );
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedShadows = shadows ??
        (elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ]
            : []);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AdminColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AdminColors.border),
        boxShadow: resolvedShadows,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        );
    return AdminCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                const SizedBox(height: 6),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AdminColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final VoidCallback? onMenu;
  final String userName;
  final VoidCallback onLogout;

  const _AdminTopBar({
    this.onMenu,
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final showName = MediaQuery.sizeOf(context).width >= 720;
    final initials = userName.trim().isNotEmpty ? userName.trim()[0] : 'A';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu),
            ),
          Expanded(
            child: Text(
              'Admin Console',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AdminColors.primary.withOpacity(0.12),
                  child: Text(initials, style: const TextStyle(color: AdminColors.primary)),
                ),
                if (showName) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  color: AdminColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AdminDrawer({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Divider(),
        for (final item in _adminNavItems)
          NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _AdminRail extends StatelessWidget {
  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AdminRail({
    required this.extended,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      backgroundColor: AdminColors.surface,
      indicatorColor: AdminColors.primary.withOpacity(0.16),
      destinations: [
        for (final item in _adminNavItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _AdminNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });
}

const _adminNavItems = [
  _AdminNavItem(
    label: 'Overview',
    route: '/admin/overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  _AdminNavItem(
    label: 'Users',
    route: '/admin/users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  _AdminNavItem(
    label: 'Lawyers',
    route: '/admin/lawyers',
    icon: Icons.gavel_outlined,
    selectedIcon: Icons.gavel,
  ),
  _AdminNavItem(
    label: 'Knowledge',
    route: '/admin/knowledge',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
  ),
  _AdminNavItem(
    label: 'Rights',
    route: '/admin/rights',
    icon: Icons.policy_outlined,
    selectedIcon: Icons.policy,
  ),
  _AdminNavItem(
    label: 'Templates',
    route: '/admin/templates',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
  ),
  _AdminNavItem(
    label: 'Pathways',
    route: '/admin/pathways',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree,
  ),
  _AdminNavItem(
    label: 'Checklists',
    route: '/admin/checklists',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
  ),
  _AdminNavItem(
    label: 'Contact',
    route: '/admin/contact',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent,
  ),
  _AdminNavItem(
    label: 'Feedback',
    route: '/admin/feedback',
    icon: Icons.feedback_outlined,
    selectedIcon: Icons.feedback,
  ),
  _AdminNavItem(
    label: 'RAG',
    route: '/admin/rag-queries',
    icon: Icons.query_stats_outlined,
    selectedIcon: Icons.query_stats,
  ),
];

int _navIndexForLocation(String location) {
  if (location.startsWith('/admin/users')) return 1;
  if (location.startsWith('/admin/lawyers')) return 2;
  if (location.startsWith('/admin/knowledge')) return 3;
  if (location.startsWith('/admin/rights')) return 4;
  if (location.startsWith('/admin/templates')) return 5;
  if (location.startsWith('/admin/pathways')) return 6;
  if (location.startsWith('/admin/checklists')) return 7;
  if (location.startsWith('/admin/contact')) return 8;
  if (location.startsWith('/admin/feedback')) return 9;
  if (location.startsWith('/admin/rag-queries')) return 10;
  return 0;
}
