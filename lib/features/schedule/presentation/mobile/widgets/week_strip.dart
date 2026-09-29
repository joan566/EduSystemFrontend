import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../shared/schedule_week.dart';

/// The seven days of the week as tappable tiles. The selected day is a
/// solid blue tile; a dot marks the days that have classes.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.week, this.daysWithClasses});

  final ScheduleWeek week;

  /// Null while the week is loading.
  final Set<DateTime>? daysWithClasses;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          for (final (i, day) in week.days.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayTile(
                day: day,
                selected: isSameDay(day, week.selectedDay),
                isToday: isSameDay(day, today),
                hasClasses: daysWithClasses?.contains(day) ?? false,
                onTap: () => week.onSelectDay(day),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasClasses,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasClasses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? Colors.white
        : isToday
        ? AppColors.accentBlue
        : colors.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      label: [
        Formatters.longDayMonth(day),
        if (isToday) 'hoy',
        if (hasClasses) 'con clases',
      ].join(', '),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 66,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentBlue
              : colors.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.shortWeekday(day),
                  style: textTheme.labelSmall?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : isToday
                        ? AppColors.accentBlue
                        : textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !hasClasses
                        ? Colors.transparent
                        : selected
                        ? Colors.white
                        : AppColors.accentBlue,
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
