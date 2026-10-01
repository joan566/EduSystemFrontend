import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/imports_provider.dart';
import '../shared/import_activity.dart';

/// Pill in the desktop header while an import runs, on every screen but
/// the import/export one: a progress ring, what it is doing and the
/// percentage. Clicking it opens the import/export screen.
class DesktopImportIndicator extends StatelessWidget {
  const DesktopImportIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ImportsProvider>().activeImport;
    if (active == null || isOnDataManagement(context)) {
      return const SizedBox.shrink();
    }
    final value = importRunProgress(active.run);
    final label = importRunLabel(active.run);
    return Tooltip(
      message: '$label\nAbrir Importar y exportar',
      child: Material(
        color: AppColors.accentBlue.withValues(alpha: 0.08),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go(RoutePaths.dataManagement),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImportProgressRing(value: value),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    label,
                    style: context.textStyles.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(value * 100).round()}%',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tablet rail's version: just the ring and the percentage under it.
class TabletImportIndicator extends StatelessWidget {
  const TabletImportIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ImportsProvider>().activeImport;
    if (active == null || isOnDataManagement(context)) {
      return const SizedBox.shrink();
    }
    final value = importRunProgress(active.run);
    return Tooltip(
      message: importRunLabel(active.run),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(RoutePaths.dataManagement),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImportProgressRing(value: value, size: 24),
              const SizedBox(height: 4),
              Text(
                value == null ? 'Importando' : '${(value * 100).round()}%',
                style: context.textStyles.labelSmall?.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small ring: determinate with a known percentage, spinning otherwise.
class ImportProgressRing extends StatelessWidget {
  const ImportProgressRing({super.key, required this.value, this.size = 18});

  final double? value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 2.5,
        color: AppColors.accentBlue,
        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
      ),
    );
  }
}
