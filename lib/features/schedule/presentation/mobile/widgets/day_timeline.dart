import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/schedule_entities.dart';
import '../../shared/schedule_widgets.dart';

const _timeColumnWidth = 52.0;
const _railWidth = 22.0;

/// One day's classes on a vertical timeline: times on the left, a dot and
/// line in the middle, the class card on the right, closed by an "end of
/// the day" marker.
class DayTimeline extends StatelessWidget {
  const DayTimeline({super.key, required this.day, required this.isToday});

  final DayScheduleEntity day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final last = day.classes.last;
    return Column(
      children: [
        for (final c in day.classes)
          _TimelineEntry(
            scheduled: c,
            status: isToday ? day.statusOf(c) : null,
          ),
        _EndOfDay(time: last.endTime, isToday: isToday),
      ],
    );
  }
}

/// Time column + rail for one row; [child] fills the rest.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.start,
    this.end,
    required this.dotColor,
    required this.showLine,
    required this.child,
    this.faded = false,
  });

  final ClockTime start;
  final ClockTime? end;
  final Color dotColor;
  final bool showLine;
  final bool faded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    start.format(),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: faded ? muted : null,
                    ),
                  ),
                  if (end != null)
                    Text(end!.format(), style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                const SizedBox(height: 19),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: showLine
                      ? Container(width: 2, color: colors.outline)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.scheduled, required this.status});

  final ScheduledClassEntity scheduled;

  /// Only for today's classes.
  final ScheduledClassStatus? status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _TimelineRow(
      start: scheduled.startTime,
      end: scheduled.endTime,
      dotColor: status == null
          ? AppColors.accentBlue
          : scheduleStatusColor(status!),
      showLine: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                TintedIcon(
                  icon: subjectIcon(scheduled.subjectName),
                  color: subjectAccent(scheduled.subjectId),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status != null) ...[
                        _StatusPill(status: status!),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        scheduled.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        scheduled.courseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                      if (scheduled.room != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                scheduled.room!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: textTheme.bodySmall?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "En curso" / "Próxima" / "Finalizada", tinted with the timeline color.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ScheduledClassStatus status;

  @override
  Widget build(BuildContext context) {
    final color = scheduleStatusColor(status);
    final label = switch (status) {
      ScheduledClassStatus.inProgress => 'En curso',
      ScheduledClassStatus.upcoming => 'Próxima',
      ScheduledClassStatus.finished => 'Finalizada',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EndOfDay extends StatelessWidget {
  const _EndOfDay({required this.time, required this.isToday});

  final ClockTime time;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return _TimelineRow(
      start: time,
      dotColor: Theme.of(context).colorScheme.outline,
      showLine: false,
      faded: true,
      child: DayNotice(
        icon: Icons.event_available_outlined,
        title: isToday ? 'No hay más clases hoy' : 'No hay más clases este día',
        message: 'Tu horario escolar termina aquí.',
      ),
    );
  }
}

/// Muted, centered notice inside the day panel (end of day, no classes).
class DayNotice extends StatelessWidget {
  const DayNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: muted),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
