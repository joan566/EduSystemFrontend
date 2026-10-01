import 'package:flutter/material.dart';

import '../../features/imports/presentation/desktop/desktop_import_indicator.dart';
import '../../features/imports/presentation/mobile/mobile_import_banner.dart';
import '../../features/imports/presentation/shared/import_activity.dart';
import '../widgets/desktop/desktop_shell.dart';
import '../widgets/mobile/mobile_shell.dart';
import 'responsive.dart';

/// The authenticated app shell (§18, §19, §20): picks the mobile shell
/// (bottom navigation) or the desktop family (sidebar on desktop, compact
/// rail on tablet). Each shell is its own implementation; they only share
/// the navigation model ([NavItem]) and the routed [child] page, which in
/// turn picks its own mobile or desktop view.
///
/// A running import follows the teacher across screens: each shell gets
/// its own indicator, and the completion notice is mounted once above the
/// fork so it shows once whatever the layout.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ImportCompletionListener(
      child: ResponsiveBuilder(
        mobile: (_) =>
            MobileShell(bottomBanner: const MobileImportBanner(), child: child),
        tablet: (_) => TabletShell(
          railStatus: const TabletImportIndicator(),
          child: child,
        ),
        desktop: (_) => DesktopShell(
          headerStatus: const DesktopImportIndicator(),
          child: child,
        ),
      ),
    );
  }
}
