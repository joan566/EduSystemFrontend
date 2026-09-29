import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule_entities.dart';
import '../../shared/schedule_week.dart';

const _hourHeight = 64.0;
const _gutterWidth = 60.0;

/// The week as a calendar: one column per day, one row per hour, each
/// class placed at its real time. Day headers select the day shown in the
/// side agenda; a line marks the current time on today's column.
class WeekTimeGrid extends StatelessWidget {
  const WeekTimeGrid({super.key, required this.week, required this.range});

  final ScheduleWeek week;
  final ScheduleRangeEntity range;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Weekend columns only when something happens on them.
    final days = range.days
        .where(
          (d) =>
              d.date.weekday <= DateTime.friday ||
              range.days
                  .where((w) => w.date.weekday > DateTime.friday)
                  .any((w) => w.classes.isNotEmpty),
        )
        .toList();
    final classes = [for (final d in days) ...d.classes];
    // Always at least a school day (7–17), stretched to fit every class.
    final firstHour = classes.fold(
      7,
      (h, c) => c.startTime.hour < h ? c.startTime.hour : h,
    );
    final lastHour = classes.fold(17, (h, c) {
      final end = c.endTime.minute > 0 ? c.endTime.hour + 1 : c.endTime.hour;
      return end > h ? end : h;
    });
    final hours = lastHour - firstHour;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 10),
            child: Row(
              children: [
                const SizedBox(width: _gutterWidth),
                for (final day in days)
                  Expanded(
                    child: _DayHeader(
                      day: day,
                      selected: isSameDay(day.date, week.selectedDay),
                      onTap: () => week.onSelectDay(day.date),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 10, 12, 16),
                    child: SizedBox(
                      height: hours * _hourHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HourGutter(firstHour: firstHour, hours: hours),
                          for (final day in days)
                            Expanded(
                              child: _DayColumn(
                                day: day,
                                firstHour: firstHour,
                                hours: hours,
                                selected: isSameDay(day.date, week.selectedDay),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (classes.isEmpty) const Center(child: _EmptyWeek()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined, color: textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sin clases esta semana', style: textTheme.titleSmall),
              Text(
                'Los bloques se agregan desde el horario de cada clase.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DayScheduleEntity day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isToday = isSameDay(day.date, day.serverTime);
    final count = day.classes.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected
            ? AppColors.accentBlue.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  Formatters.shortWeekday(day.date).toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: isToday || selected
                        ? AppColors.accentBlue
                        : textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.accentBlue : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.date.day}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? Colors.white
                          : selected
                          ? AppColors.accentBlue
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (count) {
                    0 => 'Sin clases',
                    1 => '1 clase',
                    _ => '$count clases',
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourGutter extends StatelessWidget {
  const _HourGutter({required this.firstHour, required this.hours});

  final int firstHour;
  final int hours;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);
    return SizedBox(
      width: _gutterWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i <= hours; i++)
            Positioned(
              top: i * _hourHeight - 7,
              right: 10,
              child: Text(
                '${(firstHour + i).toString().padLeft(2, '0')}:00',
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.firstHour,
    required this.hours,
    required this.selected,
  });

  final DayScheduleEntity day;
  final int firstHour;
  final int hours;
  final bool selected;

  double _offsetOf(int minutesOfDay) =>
      (minutesOfDay - firstHour * 60) / 60 * _hourHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = day.serverTime;
    final isToday = isSameDay(day.date, now);
    final nowOffset = _offsetOf(now.hour * 60 + now.minute);
    final showNow =
        isToday && nowOffset >= 0 && nowOffset <= hours * _hourHeight;

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accentBlue.withValues(alpha: 0.03)
            : isToday
            ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
            : null,
        border: Border(left: BorderSide(color: colors.outline)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i <= hours; i++)
            Positioned(
              top: i * _hourHeight,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.outline.withValues(alpha: 0.6),
              ),
            ),
          for (final c in day.classes)
            Positioned(
              top: _offsetOf(c.startTime.minutesOfDay) + 2,
              height:
                  _offsetOf(c.endTime.minutesOfDay) -
                  _offsetOf(c.startTime.minutesOfDay) -
                  4,
              left: 4,
              right: 4,
              child: _ClassBlock(
                scheduled: c,
                finished: day.statusOf(c) == ScheduledClassStatus.finished,
                inProgress:
                    isToday &&
                    day.statusOf(c) == ScheduledClassStatus.inProgress,
              ),
            ),
          if (showNow)
            Positioned(
              top: nowOffset - 4,
              left: -4,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(height: 2, color: AppColors.accentBlue),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassBlock extends StatefulWidget {
  const _ClassBlock({
    required this.scheduled,
    required this.finished,
    required this.inProgress,
  });

  final ScheduledClassEntity scheduled;
  final bool finished;
  final bool inProgress;

  @override
  State<_ClassBlock> createState() => _ClassBlockState();
}

class _ClassBlockState extends State<_ClassBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.scheduled;
    final color = subjectAccent(c.subjectId);
    final details = [c.courseLabel, if (c.room != null) c.room!].join(' · ');
    final tint = (dark ? 0.22 : 0.1) + (_hovered ? 0.08 : 0);

    return Tooltip(
      message:
          '${c.subjectName} · $details\n'
          '${formatTimeRange(c.startTime, c.endTime)} · ${c.academicPeriodName}',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () =>
              context.push(RoutePaths.teachingPeriodDetail(c.teachingPeriodId)),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: widget.finished && !_hovered ? 0.55 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: color.withValues(alpha: tint),
                borderRadius: BorderRadius.circular(10),
                border: widget.inProgress
                    ? Border.all(color: color, width: 1.5)
                    : null,
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 6, 4),
                      // Short blocks cut the last lines; the tooltip has
                      // everything.
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              formatTimeRange(c.startTime, c.endTime),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
