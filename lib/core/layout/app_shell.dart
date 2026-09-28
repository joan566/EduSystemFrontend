import 'package:flutter/material.dart';

import '../widgets/desktop/desktop_shell.dart';
import '../widgets/mobile/mobile_shell.dart';
import 'responsive.dart';

/// The authenticated app shell (§18, §19, §20): picks the mobile shell
/// (bottom navigation) or the desktop family (sidebar on desktop, compact
/// rail on tablet). Each shell is its own implementation; they only share
/// the navigation model ([NavItem]) and the routed [child] page, which in
/// turn picks its own mobile or desktop view.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => MobileShell(child: child),
      tablet: (_) => TabletShell(child: child),
      desktop: (_) => DesktopShell(child: child),
    );
  }
}
