import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/nav_items.dart';
import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';

/// Mobile app shell: the routed page above a bottom navigation bar with
/// the primary destinations plus "Más" (§19, §107).
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final onMore = currentPath.startsWith(RoutePaths.more);
    final selectedIndex = onMore
        ? primaryNavItems.length
        : primaryNavItems.indexWhere(
            (item) => isNavItemActive(currentPath, item),
          );

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: MobileBottomNav(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (index) {
          if (index == primaryNavItems.length) {
            context.push(RoutePaths.more);
          } else {
            context.go(primaryNavItems[index].path);
          }
        },
      ),
    );
  }
}

/// Bottom navigation: [primaryNavItems] + "Más", with the active item in
/// an accent-blue pill.
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final idle = colors.onSurface.withValues(alpha: 0.65);

    return NavigationBarTheme(
      data: NavigationBarTheme.of(context).copyWith(
        indicatorColor: AppColors.accentBlue.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.accentBlue
                : idle,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? labelStyle?.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w700,
                )
              : labelStyle?.copyWith(color: idle, fontWeight: FontWeight.w500),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in primaryNavItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
