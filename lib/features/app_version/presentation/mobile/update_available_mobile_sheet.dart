import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../domain/entities/semantic_version.dart';
import '../shared/app_update_copy.dart';

/// Phone: the optional-update notice as a bottom sheet over the app.
class UpdateAvailableMobileSheet extends StatelessWidget {
  const UpdateAvailableMobileSheet({
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.shadowStrong,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: MobileSheetFrame(
              title: AppUpdateCopy.availableTitle,
              actions: [
                AppButton(
                  label: AppUpdateCopy.keepUsing,
                  variant: AppButtonVariant.outlined,
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
