import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/brand_logo.dart';
import '../../domain/entities/semantic_version.dart';
import '../shared/app_update_copy.dart';

/// Desktop: an elevated card centered on the page background, like the
/// login card, with the brand above it. No back action.
class UpdateRequiredDesktopView extends StatelessWidget {
  const UpdateRequiredDesktopView({
    super.key,
    required this.installed,
    required this.minimum,
    required this.onUpdate,
  });

  final SemanticVersion installed;
  final SemanticVersion minimum;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandLogo(size: 36),
                    const SizedBox(width: 12),
                    Text(
                      'EduSistem',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      UpdateRequiredContent(
                        installed: installed,
                        minimum: minimum,
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        label: AppUpdateCopy.update,
                        icon: Icons.system_update_alt_rounded,
                        expand: true,
                        onPressed: onUpdate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
