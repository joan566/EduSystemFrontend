import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/brand_logo.dart';
import '../../domain/entities/semantic_version.dart';
import '../shared/app_update_copy.dart';

/// Phone: full screen, brand on top, the update action pinned at the bottom.
/// There is no way back or around it.
class UpdateRequiredMobileView extends StatelessWidget {
  const UpdateRequiredMobileView({
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const BrandLogo(size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'EduSistem',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 36),
                      UpdateRequiredContent(
                        installed: installed,
                        minimum: minimum,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AppButton(
                label: AppUpdateCopy.update,
                icon: Icons.system_update_alt_rounded,
                expand: true,
                onPressed: onUpdate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
