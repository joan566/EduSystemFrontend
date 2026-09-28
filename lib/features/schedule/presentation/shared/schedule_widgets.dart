import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/schedule_entities.dart';

/// "En curso" / "Próxima" / "Finalizada" pill.
class ScheduleStatusChip extends StatelessWidget {
  const ScheduleStatusChip({super.key, required this.status});

  final ScheduledClassStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      ScheduledClassStatus.inProgress => (
        'En curso',
        AppColors.success,
        AppColors.successBg,
      ),
      ScheduledClassStatus.upcoming => (
        'Próxima',
        AppColors.textSecondary,
        AppColors.surfaceMuted,
      ),
      ScheduledClassStatus.finished => (
        'Finalizada',
        AppColors.textDisabled,
        AppColors.surfaceMuted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Timeline dot color for a class status.
Color scheduleStatusColor(ScheduledClassStatus status) => switch (status) {
  ScheduledClassStatus.inProgress => AppColors.success,
  ScheduledClassStatus.upcoming => AppColors.accentBlue,
  ScheduledClassStatus.finished => AppColors.textDisabled,
};
