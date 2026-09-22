import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../router/nav_items.dart';
import '../router/route_paths.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'app_confirm_dialog.dart';

bool _isActive(String currentPath, String itemPath) {
  if (itemPath == RoutePaths.dashboard) return currentPath == itemPath;
  return currentPath.startsWith(itemPath);
}

/// Real page context for the header (§ "¿sé dónde estoy?") — derived from
/// the actual route, not decorative. Dashboard gets no label since its own
/// hero banner already says "Bienvenido".
String? _currentPageLabel(String currentPath) {
  if (currentPath == RoutePaths.dashboard) return null;
  for (final item in [
    ...primaryNavItems,
    ...secondaryNavItems,
    ...catalogNavItems,
    ...systemNavItems,
    profileNavItem,
  ]) {
    if (_isActive(currentPath, item.path)) return item.label;
  }
  return null;
}

Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await confirmLogout(context);
  if (confirmed && context.mounted) {
    await context.read<AuthProvider>().logout();
  }
}

/// The authenticated app shell (§18, §19, §20): sidebar on desktop, a
/// reduced rail on tablet, bottom navigation on mobile. All three share the
/// same [child] page content and the same navigation model ([NavItem]).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => _MobileShell(child: child),
      tablet: (_) => _TabletShell(child: child),
      desktop: (_) => _DesktopShell(child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop
// ---------------------------------------------------------------------------

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              collapsed: _collapsed,
              currentPath: currentPath,
              onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
            ),
            Expanded(
              child: Column(
                children: [
                  const _Header(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.currentPath,
    required this.onToggleCollapse,
  });

  final bool collapsed;
  final String currentPath;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 76.0 : 248.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.brandGradient,
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Logo(collapsed: collapsed),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in primaryNavItems)
                    _SidebarTile(
                      item: item,
                      collapsed: collapsed,
                      active: _isActive(currentPath, item.path),
                    ),
                  _SectionLabel(collapsed: collapsed, label: 'Evaluación'),
                  for (final item in secondaryNavItems)
                    _SidebarTile(
                      item: item,
                      collapsed: collapsed,
                      active: _isActive(currentPath, item.path),
                    ),
                  _SectionLabel(collapsed: collapsed, label: 'Catálogo'),
                  for (final item in catalogNavItems)
                    _SidebarTile(
                      item: item,
                      collapsed: collapsed,
                      active: _isActive(currentPath, item.path),
                    ),
                  _SectionLabel(collapsed: collapsed, label: 'Sistema'),
                  for (final item in systemNavItems)
                    _SidebarTile(
                      item: item,
                      collapsed: collapsed,
                      active: _isActive(currentPath, item.path),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _SidebarTile(
              item: profileNavItem,
              collapsed: collapsed,
              active: _isActive(currentPath, profileNavItem.path),
            ),
          ),
          if (!collapsed) const _SecurityBadge(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
            child: Align(
              alignment: collapsed ? Alignment.center : Alignment.centerRight,
              child: IconButton(
                onPressed: onToggleCollapse,
                tooltip: collapsed ? 'Expandir' : 'Colapsar',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
                icon: Icon(
                  collapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small trust signal at the base of the sidebar — a quiet, persistent
/// reminder that the session is authenticated and the connection is
/// encrypted, reinforcing the "professional/secure" tone the product wants.
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 6),
          Text(
            'Conexión segura',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'EduSistem',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.collapsed, required this.label});

  final bool collapsed;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (collapsed) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.collapsed,
    required this.active,
  });

  final NavItem item;
  final bool collapsed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: active ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (!collapsed)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              Icon(
                active ? item.activeIcon : item.icon,
                size: 20,
                color: active ? Colors.white : Colors.white70,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!collapsed) {
      return Padding(padding: const EdgeInsets.only(bottom: 2), child: tile);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(message: item.label, child: tile),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final colors = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;
    final currentLabel = _currentPageLabel(currentPath);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.6)),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentLabel != null)
            Text(currentLabel, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'profile') context.go(RoutePaths.profile);
              if (value == 'logout') _handleLogout(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mi perfil'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.initials ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  user?.fullName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet
// ---------------------------------------------------------------------------

class _TabletShell extends StatelessWidget {
  const _TabletShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = primaryNavItems.indexWhere(
      (item) => _isActive(currentPath, item.path),
    );

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex < 0 ? null : selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(primaryNavItems[index].path),
              labelType: NavigationRailLabelType.all,
              leading: const SizedBox(height: 8),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Más',
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => context.push(RoutePaths.more),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final item in primaryNavItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile
// ---------------------------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final onMore = currentPath.startsWith(RoutePaths.more);
    final selectedIndex = onMore
        ? primaryNavItems.length
        : primaryNavItems.indexWhere(
            (item) => _isActive(currentPath, item.path),
          );

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) {
          if (index == primaryNavItems.length) {
            context.push(RoutePaths.more);
          } else {
            context.go(primaryNavItems[index].path);
          }
        },
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
