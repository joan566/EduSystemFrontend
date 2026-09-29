import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../domain/entities/schedule_entities.dart';
import '../../shared/schedule_week.dart';
import '../../shared/schedule_widgets.dart';

/// The selected day as an agenda: today's current/next class on top, then
/// every class in order.
class DayAgendaCard extends StatelessWidget {
  const DayAgendaCard({super.key, required this.day});

  final DayScheduleEntity day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isToday = isSameDay(day.date, day.serverTime);
    final next = isToday ? day.nextClass : null;

    return DesktopSectionCard(
      icon: Icons.view_agenda_outlined,
      title: isToday ? 'Hoy' : Formatters.weekdayName(day.date.weekday),
      subtitle: Formatters.shortDayMonth(day.date),
      child: day.classes.isEmpty
          ? _Muted(
              icon: Icons.event_busy_outlined,
              text: 'No tienes clases programadas este día.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (next != null) ...[
                  _NowCard(
                    scheduled: next,
                    inProgress:
                        day.statusOf(next) == ScheduledClassStatus.inProgress,
                    now: day.serverTime,
                  ),
                  const SizedBox(height: 14),
                ] else if (isToday) ...[
                  _Muted(
                    icon: Icons.event_available_outlined,
                    text: 'Terminaste tus clases de hoy.',
                  ),
                  const SizedBox(height: 14),
                ],
                for (final c in day.classes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DesktopHoverTile(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      onTap: () => context.push(
                        RoutePaths.teachingPeriodDetail(c.teachingPeriodId),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 46,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.startTime.format(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  c.endTime.format(),
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 34,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: subjectAccent(c.subjectId),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [
                                    c.courseLabel,
                                    if (c.room != null) c.room!,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isToday)
                            ScheduleStatusChip(status: day.statusOf(c)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The class in progress or next to start, with how long until it starts
/// or ends.
class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.scheduled,
    required this.inProgress,
    required this.now,
  });

  final ScheduledClassEntity scheduled;
  final bool inProgress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = inProgress ? AppColors.success : AppColors.accentBlue;
    final target = (inProgress ? scheduled.endTime : scheduled.startTime).on(
      now,
    );
    final minutes = target.difference(now).inMinutes;
    final when = inProgress
        ? 'Termina en ${formatMinutes(minutes)}'
        : 'Empieza en ${formatMinutes(minutes)}';

    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inProgress ? 'En curso' : 'Próxima clase',
                      style: textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      scheduled.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${scheduled.courseLabel}  ·  $when',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Totals for the week and how the teaching hours split by subject.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.range});

  final ScheduleRangeEntity range;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final classes = [for (final d in range.days) ...d.classes];
    int minutesOf(ScheduledClassEntity c) =>
        c.endTime.minutesOfDay - c.startTime.minutesOfDay;
    final totalMinutes = classes.fold(0, (sum, c) => sum + minutesOf(c));
    final courses = {for (final c in classes) c.groupId}.length;

    final bySubject = <int, ({String name, int minutes})>{};
    for (final c in classes) {
      final prev = bySubject[c.subjectId];
      bySubject[c.subjectId] = (
        name: c.subjectName,
        minutes: (prev?.minutes ?? 0) + minutesOf(c),
      );
    }
    final subjects = bySubject.entries.toList()
      ..sort((a, b) => b.value.minutes.compareTo(a.value.minutes));
    final maxMinutes = subjects.isEmpty ? 1 : subjects.first.value.minutes;

    return DesktopSectionCard(
      icon: Icons.insights_outlined,
      title: 'Resumen de la semana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Figure(value: '${classes.length}', label: 'Clases'),
              _Figure(value: formatMinutes(totalMinutes), label: 'En aula'),
              _Figure(value: '$courses', label: 'Cursos'),
            ],
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Horas por materia', style: textTheme.labelLarge),
            const SizedBox(height: 10),
            for (final s in subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.value.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Text(
                          formatMinutes(s.value.minutes),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.value.minutes / maxMinutes,
                        minHeight: 6,
                        color: subjectAccent(s.key),
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: textTheme.bodySmall)),
      ],
    );
  }
}

/// "45 min", "2 h", "3 h 30 min".
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}
