import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';

/// Class picker as a button that opens a menu of the teacher's classes.
class AttendanceClassMenu extends StatelessWidget {
  const AttendanceClassMenu({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final periods = context.watch<TeachingProvider>().allPeriods;
    final period = this.period;

    return PopupMenuButton<TeachingPeriodEntity>(
      tooltip: 'Cambiar de clase',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 340, maxWidth: 420),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final p in periods)
          PopupMenuItem(
            value: p,
            child: Row(
              children: [
                TintedIcon(
                  icon: subjectIcon(p.subjectName),
                  color: subjectAccent(p.subjectId),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.subjectName} — ${p.courseLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${p.academicPeriodName} · ${p.studentCount} estudiantes',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (p.id == period?.id)
                  const Icon(
                    Icons.check,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintedIcon(
              icon: period == null
                  ? Icons.class_outlined
                  : subjectIcon(period.subjectName),
              color: period == null
                  ? AppColors.accentBlue
                  : subjectAccent(period.subjectId),
              size: 38,
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period == null
                        ? 'Selecciona una clase'
                        : '${period.subjectName} — ${period.courseLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (period != null)
                    Text(
                      '${period.academicPeriodName} · '
                      '${period.studentCount} estudiantes',
                      maxLines: 1,
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.unfold_more,
              size: 20,
              color: textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}

/// ‹ date › : previous/next class day (by the class's schedule), the date
/// itself opens a picker, plus "Hoy".
class AttendanceDateNavigator extends StatelessWidget {
  const AttendanceDateNavigator({
    super.key,
    required this.period,
    required this.date,
    required this.meetingDays,
    required this.room,
    required this.onChanged,
  });

  final TeachingPeriodEntity period;
  final DateTime date;

  /// ISO weekdays the class meets; empty = step one day at a time.
  final Set<int> meetingDays;
  final String? room;
  final ValueChanged<DateTime> onChanged;

  /// The next date in [direction] (±1) the class meets, within its dates.
  DateTime? _step(int direction) {
    var d = date;
    for (var i = 0; i < 14; i++) {
      d = DateTime(d.year, d.month, d.day + direction);
      if (d.isBefore(period.startDate) || d.isAfter(period.endDate)) {
        return null;
      }
      if (meetingDays.isEmpty || meetingDays.contains(d.weekday)) return d;
    }
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: period.startDate,
      lastDate: period.endDate,
      helpText: 'Fecha de la asistencia',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final previous = _step(-1);
    final next = _step(1);
    final today = DateUtils.dateOnly(DateTime.now());
    final canGoToday =
        date != today &&
        !today.isBefore(period.startDate) &&
        !today.isAfter(period.endDate);
    final stepHint = meetingDays.isEmpty ? 'Día' : 'Clase';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '$stepHint anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: previous == null ? null : () => onChanged(previous),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pick(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Formatters.longDayMonth(date)} de ${date.year}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            [
                              if (date == today) 'Hoy',
                              ?room,
                              if (meetingDays.isNotEmpty &&
                                  !meetingDays.contains(date.weekday))
                                'Sin clase en el horario',
                            ].join(' · ').ifEmpty('Cambiar fecha'),
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: '$stepHint siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: next == null ? null : () => onChanged(next),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: canGoToday ? () => onChanged(today) : null,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
          child: const Text('Hoy'),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
