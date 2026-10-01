import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_version_policy.dart';
import '../desktop/update_available_desktop_dialog.dart';
import '../desktop/update_required_desktop_view.dart';
import '../mobile/update_available_mobile_sheet.dart';
import '../mobile/update_required_mobile_view.dart';
import '../providers/app_version_provider.dart';

/// Wraps the whole app (`MaterialApp.builder`), above the router, so the
/// version policy applies to every screen — login, splash and the app
/// alike — whatever the session.
///
/// - [AppVersionStatus.updateRequired]: [child] (the router and every
///   route) is removed from the tree and replaced by the update screen.
///   Nothing can be navigated to or dismissed; only "Actualizar".
/// - Optional update: the notice sits over [child] until "Continuar".
/// - Otherwise (current, or not known): [child] untouched.
class AppVersionGate extends StatelessWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppVersionProvider>();

    if (version.status == AppVersionStatus.updateRequired) {
      final installed = version.installedVersion!;
      final minimum = version.minimumVersion!;
      return ResponsiveBuilder(
        mobile: (_) => UpdateRequiredMobileView(
          installed: installed,
          minimum: minimum,
          onUpdate: version.openUpdate,
        ),
        desktop: (_) => UpdateRequiredDesktopView(
          installed: installed,
          minimum: minimum,
          onUpdate: version.openUpdate,
        ),
      );
    }

    // Always the same Stack around [child], so the notice coming and going
    // never rebuilds the app's navigator (and its state) underneath.
    final prompt = version.showOptionalPrompt;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(excluding: prompt, child: child),
        if (prompt) ...[
          ModalBarrier(
            dismissible: false,
            color: AppColors.primaryDarkest.withValues(alpha: 0.45),
          ),
          ResponsiveBuilder(
            mobile: (_) => UpdateAvailableMobileSheet(
              installed: version.installedVersion!,
              latest: version.latestVersion!,
              onUpdate: version.openUpdate,
              onContinue: version.dismissOptional,
            ),
            desktop: (_) => UpdateAvailableDesktopDialog(
              installed: version.installedVersion!,
              latest: version.latestVersion!,
              onUpdate: version.openUpdate,
              onContinue: version.dismissOptional,
            ),
          ),
        ],
      ],
    );
  }
}
