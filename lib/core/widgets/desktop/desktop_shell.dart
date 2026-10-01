import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../router/nav_items.dart';
import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';
import '../shared/app_confirm_dialog.dart';
import '../shared/brand_logo.dart';

/// Real page context for the header (§ "¿sé dónde estoy?") — derived from
/// the actual route, not decorative. Dashboard gets no label since its own
/// hero banner already says "Bienvenido".
String? _currentPageLabel(String currentPath) {
  if (currentPath == RoutePaths.dashboard) return null;
  for (final item in [
    ...primaryNavItems,
    scheduleNavItem,
    ...secondaryNavItems,
    ...catalogNavItems,
    ...settingsNavItems,
    ...systemNavItems,
    profileNavItem,
  ]) {
    if (isNavItemActive(currentPath, item)) return item.label;
  }
  return null;
}

Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await confirmLogout(context);
  if (confirmed && context.mounted) {
    await context.read<AuthProvider>().logout();
  }
}

// ---------------------------------------------------------------------------
// Desktop
// ---------------------------------------------------------------------------

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.child, this.headerStatus});

  final Widget child;

  /// Shown in the header next to the user menu on every screen (e.g. an
  /// import in progress); it collapses itself when it has nothing to say.
  final Widget? headerStatus;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  /// Null until the user toggles it: then the sidebar follows the window
  /// (compact below [_autoCollapseWidth]).
  bool? _collapsed;

  static const _autoCollapseWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final collapsed =
        _collapsed ?? MediaQuery.sizeOf(context).width < _autoCollapseWidth;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              collapsed: collapsed,
              currentPath: currentPath,
              onToggleCollapse: () => setState(() => _collapsed = !collapsed),
            ),
            Expanded(
              child: Column(
                children: [
                  _Header(status: widget.headerStatus),
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

/// A titled group of destinations; untitled for the day-to-day ones.
class _NavSection {
  const _NavSection(this.title, this.items);

  final String? title;
  final List<NavItem> items;
}

final _sections = [
  _NavSection(null, [...primaryNavItems, scheduleNavItem]),
  const _NavSection('Evaluación', secondaryNavItems),
  const _NavSection('Catálogo', catalogNavItems),
  const _NavSection('Configuración', settingsNavItems),
  const _NavSection('Sistema', systemNavItems),
];

/// Light, quiet sidebar in the style of the app's screens: brand mark,
/// destinations grouped in foldable sections (the active one opens by
/// itself), the active page as a vivid blue pill, and the user at the
/// bottom. Collapses to an icon rail with tooltips.
class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.collapsed,
    required this.currentPath,
    required this.onToggleCollapse,
  });

  final bool collapsed;
  final String currentPath;
  final VoidCallback onToggleCollapse;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  /// Sections the user folded; one holding the current page never folds.
  final Set<String> _folded = {};

  @override
  Widget build(BuildContext context) {
    final collapsed = widget.collapsed;
    final colors = Theme.of(context).colorScheme;
    final width = collapsed ? 76.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.outline.withValues(alpha: 0.7)),
        ),
      ),
      // The content is laid out at its final width and clipped while the
      // width animates, so it never squeezes mid-transition.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: width - 1,
          maxWidth: width - 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Brand(
                collapsed: collapsed,
                onToggleCollapse: widget.onToggleCollapse,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    collapsed ? 12 : 14,
                    8,
                    collapsed ? 12 : 14,
                    16,
                  ),
                  children: [
                    for (final section in _sections) ..._section(section),
                  ],
                ),
              ),
              _UserCard(collapsed: collapsed, currentPath: widget.currentPath),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _section(_NavSection section) {
    final collapsed = widget.collapsed;
    final title = section.title;
    final holdsCurrent = section.items.any(
      (i) => isNavItemActive(widget.currentPath, i),
    );
    final open =
        title == null || collapsed || holdsCurrent || !_folded.contains(title);

    return [
      if (title != null)
        collapsed
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : _SectionHeader(
                title: title,
                open: open,
                locked: holdsCurrent,
                onTap: () => setState(() {
                  if (!_folded.remove(title)) _folded.add(title);
                }),
              ),
      AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: open
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in section.items)
                    _NavTile(
                      item: item,
                      collapsed: collapsed,
                      active: isNavItemActive(widget.currentPath, item),
                    ),
                ],
              )
            : const SizedBox(width: double.infinity),
      ),
    ];
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed, required this.onToggleCollapse});

  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    const mark = BrandLogo(size: 36);
    final toggle = IconButton(
      tooltip: collapsed ? 'Expandir menú' : 'Contraer menú',
      onPressed: onToggleCollapse,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        collapsed
            ? Icons.keyboard_double_arrow_right
            : Icons.keyboard_double_arrow_left,
        size: 20,
        color: colors.onSurface.withValues(alpha: 0.55),
      ),
    );

    // Same height as the page header, so both lines align.
    return SizedBox(
      height: collapsed ? 104 : 64,
      child: collapsed
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [mark, const SizedBox(height: 6), toggle],
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
              child: Row(
                children: [
                  mark,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduSistem',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Panel docente',
                          style: textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  toggle,
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.open,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final bool open;

  /// Holds the current page, so it can't fold.
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: locked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (!locked)
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: open ? 0 : -0.25,
                  child: Icon(Icons.expand_more, size: 16, color: muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.collapsed,
    required this.active,
  });

  final NavItem item;
  final bool collapsed;
  final bool active;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final active = widget.active;
    final collapsed = widget.collapsed;
    final colors = Theme.of(context).colorScheme;
    final foreground = active
        ? Colors.white
        : colors.onSurface.withValues(alpha: _hovering ? 0.9 : 0.72);

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentBlue
              : _hovering
              ? colors.surfaceContainerHighest.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go(item.path),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 12,
                vertical: 11,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    size: 20,
                    color: foreground,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: collapsed
          ? Tooltip(
              message: item.label,
              waitDuration: const Duration(milliseconds: 300),
              child: tile,
            )
          : tile,
    );
  }
}

/// The signed-in teacher at the bottom: profile and sign-out in a menu.
class _UserCard extends StatelessWidget {
  const _UserCard({required this.collapsed, required this.currentPath});

  final bool collapsed;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onProfile = isNavItemActive(currentPath, profileNavItem);

    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.accentBlue.withValues(alpha: 0.14),
      child: Text(
        user?.initials ?? '',
        style: textTheme.labelMedium?.copyWith(
          color: AppColors.accentBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(collapsed ? 10 : 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.7)),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Tu cuenta',
        position: PopupMenuPosition.over,
        offset: const Offset(0, -110),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(collapsed ? 4 : 8),
          decoration: BoxDecoration(
            color: onProfile
                ? AppColors.accentBlue.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: collapsed
              ? Center(child: avatar)
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.unfold_more,
                      size: 18,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.status});

  final Widget? status;

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
          if (status != null) ...[status!, const SizedBox(width: 16)],
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
                    backgroundColor: AppColors.accentBlue,
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
// Tablet — desktop family, with a compact rail instead of the full sidebar.
// ---------------------------------------------------------------------------

class TabletShell extends StatelessWidget {
  const TabletShell({super.key, required this.child, this.railStatus});

  final Widget child;

  /// Shown at the foot of the rail, above "Más" (e.g. an import in
  /// progress); it collapses itself when it has nothing to say.
  final Widget? railStatus;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = primaryNavItems.indexWhere(
      (item) => isNavItemActive(currentPath, item),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ?railStatus,
                        IconButton(
                          tooltip: 'Más',
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () => context.push(RoutePaths.more),
                        ),
                      ],
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
