import 'package:flutter/material.dart';

import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../domain/entities/semantic_version.dart';
import '../shared/app_update_copy.dart';

/// Desktop: the optional-update notice as a centered dialog over the app.
/// It lives above the app's navigator, so closing it is [onContinue], not a
/// route pop.
class UpdateAvailableDesktopDialog extends StatelessWidget {
  const UpdateAvailableDesktopDialog({
    super.key,
    required this.installed,
    required this.latest,
    required this.onUpdate,
    required this.onContinue,
  });

  final SemanticVersion installed;
  final SemanticVersion latest;
  final VoidCallback onUpdate;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final dialogTheme = DialogTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: dialogTheme.backgroundColor,
            elevation: dialogTheme.elevation ?? 4,
            shadowColor: dialogTheme.shadowColor,
            shape: dialogTheme.shape,
            clipBehavior: Clip.antiAlias,
            child: DesktopDialogFrame(
              title: AppUpdateCopy.availableTitle,
              onClose: onContinue,
              actions: [
                AppButton(
                  label: AppUpdateCopy.keepUsing,
                  variant: AppButtonVariant.text,
                  onPressed: onContinue,
                ),
                AppButton(label: AppUpdateCopy.update, onPressed: onUpdate),
              ],
              child: UpdateAvailableContent(
                installed: installed,
                latest: latest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
