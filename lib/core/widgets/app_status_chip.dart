import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppStatusKind { success, error, warning, info, neutral }

/// Small colored status indicator (e.g. submission status, active/inactive,
/// PRESENT/ABSENT). Color is used for meaning, not decoration (§7).
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.kind});

  final String label;
  final AppStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (kind) {
      AppStatusKind.success => (AppColors.successBg, AppColors.success),
      AppStatusKind.error => (AppColors.errorBg, AppColors.error),
      AppStatusKind.warning => (AppColors.warningBg, AppColors.warning),
      AppStatusKind.info => (AppColors.infoBg, AppColors.info),
      AppStatusKind.neutral => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
