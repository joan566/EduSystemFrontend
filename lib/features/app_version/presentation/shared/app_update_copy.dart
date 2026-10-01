import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../domain/entities/semantic_version.dart';

/// UI copy of the update screens.
class AppUpdateCopy {
  AppUpdateCopy._();

  static const update = 'Actualizar';
  static const keepUsing = 'Continuar';

  static const requiredTitle = 'Actualiza EduSistem para continuar';
  static const requiredMessage =
      'Esta versión de EduSistem ya no es compatible. Instala la versión '
      'más reciente para seguir usando la aplicación.';
  static const installed = 'Versión instalada';
  static const minimum = 'Versión mínima';

  static const availableTitle = 'Hay una nueva versión de EduSistem';
  static const availableMessage =
      'Trae mejoras y correcciones. Puedes actualizar ahora o seguir usando '
      'esta versión.';
  static const youHave = 'Tienes';
  static const available = 'Disponible';
}

/// Body of the required-update screen: icon, message and the installed vs
/// minimum versions. Each view adds its own chrome and the update action.
class UpdateRequiredContent extends StatelessWidget {
  const UpdateRequiredContent({
    super.key,
    required this.installed,
    required this.minimum,
  });

  final SemanticVersion installed;
  final SemanticVersion minimum;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TintedIcon(
          icon: Icons.system_update_rounded,
          color: AppColors.accentBlue,
          size: 64,
          circle: true,
        ),
        const SizedBox(height: 20),
        Text(
          AppUpdateCopy.requiredTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          AppUpdateCopy.requiredMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        VersionComparison(
          rows: [
            (AppUpdateCopy.installed, installed),
            (AppUpdateCopy.minimum, minimum),
          ],
        ),
      ],
    );
  }
}

/// Body of the optional-update notice.
class UpdateAvailableContent extends StatelessWidget {
  const UpdateAvailableContent({
    super.key,
    required this.installed,
    required this.latest,
  });

  final SemanticVersion installed;
  final SemanticVersion latest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const TintedIcon(
              icon: Icons.system_update_rounded,
              color: AppColors.accentBlue,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppUpdateCopy.availableMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        VersionComparison(
          rows: [
            (AppUpdateCopy.youHave, installed),
            (AppUpdateCopy.available, latest),
          ],
        ),
      ],
    );
  }
}

/// Label / version rows on a muted panel.
class VersionComparison extends StatelessWidget {
  const VersionComparison({super.key, required this.rows});

  final List<(String, SemanticVersion)> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  rows[i].$2.toString(),
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
