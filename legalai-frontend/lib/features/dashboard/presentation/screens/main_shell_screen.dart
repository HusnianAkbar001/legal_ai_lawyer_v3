import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final useRail = size.width >= 900;
    final extendRail = size.width >= 1200;
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0, initialLocation: true);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (useRail)
                NavigationRail(
                  extended: extendRail,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTap(context, index),
                  labelType: extendRail ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: AppPalette.primary),
                      label: Text(l10n.home),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble, color: AppPalette.primary),
                      label: Text(l10n.chat),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.library_books_outlined),
                      selectedIcon: Icon(Icons.library_books, color: AppPalette.primary),
                      label: Text(l10n.library),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.checklist_rtl_outlined),
                      selectedIcon: Icon(Icons.checklist_rtl, color: AppPalette.primary),
                      label: Text(l10n.checklists),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outlined),
                      selectedIcon: Icon(Icons.people, color: AppPalette.primary),
                      label: Text(l10n.lawyers),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: AppPalette.primary),
                      label: Text(l10n.profile),
                    ),
                  ],
                ),
              Expanded(child: navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onTap(context, index),
                indicatorColor: AppPalette.primary.withOpacity(0.12),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home, color: AppPalette.primary),
                    label: l10n.home,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble, color: AppPalette.primary),
                    label: l10n.chat,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_books_outlined),
                    selectedIcon: Icon(Icons.library_books, color: AppPalette.primary),
                    label: l10n.library,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_rtl_outlined),
                    selectedIcon: Icon(Icons.checklist_rtl, color: AppPalette.primary),
                    label: l10n.checklists,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outlined),
                    selectedIcon: Icon(Icons.people, color: AppPalette.primary),
                    label: l10n.lawyers,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: AppPalette.primary),
                    label: l10n.profile,
                  ),
                ],
              ),
      ),
    );
  }
}
