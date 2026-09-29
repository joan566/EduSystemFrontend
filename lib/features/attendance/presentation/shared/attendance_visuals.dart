import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/attendance_entity.dart';

/// Label, icon and color of each attendance status, shared by both views.
({String label, IconData icon, Color color}) attendanceVisuals(
  AttendanceStatus status,
) => switch (status) {
  AttendanceStatus.present => (
    label: 'Presente',
    icon: Icons.check_rounded,
    color: AppColors.success,
  ),
  AttendanceStatus.absent => (
    label: 'Ausente',
    icon: Icons.close_rounded,
    color: AppColors.error,
  ),
  AttendanceStatus.excused => (
    label: 'Justificada',
    icon: Icons.remove_rounded,
    color: AppColors.textSecondary,
  ),
};

/// Pill with the status (or "Sin marcar"): a filled round icon and the
/// label on a light tint.
class AttendanceStatusPill extends StatelessWidget {
  const AttendanceStatusPill({super.key, required this.status});

  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = this.status;
    final colors = Theme.of(context).colorScheme;
    final visuals = status == null ? null : attendanceVisuals(status);
    final color =
        visuals?.color ?? textTheme.bodySmall?.color ?? colors.outline;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: visuals == null
            ? Colors.transparent
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: visuals == null ? Border.all(color: colors.outline) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: visuals == null ? null : color,
              shape: BoxShape.circle,
              border: visuals == null
                  ? Border.all(color: colors.outline, width: 1.5)
                  : null,
            ),
            child: visuals == null
                ? null
                : Icon(visuals.icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            visuals?.label ?? 'Sin marcar',
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
