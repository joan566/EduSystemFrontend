import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/schedule_entities.dart';
import '../providers/schedule_provider.dart';
import '../shared/schedule_week.dart';
import 'widgets/day_timeline.dart';
import 'widgets/week_strip.dart';

/// Mobile: a week strip on top and the selected day as a timeline below.
/// Swiping sideways moves a week; the header button jumps to any date.
class ScheduleMobileView extends StatelessWidget {
  const ScheduleMobileView({super.key, required this.week});

  final ScheduleWeek week;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: week.selectedDay,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Ir a una fecha',
    );
    if (picked != null) week.onSelectDay(picked);
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) week.onNext();
    if (velocity > 300) week.onPrevious();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().calendar(
      week.start,
      week.start.add(const Duration(days: 6)),
    );
    final range = state.status == DetailStatus.success ? state.data : null;

    return Scaffold(
      body: Column(
        children: [
          MobileCatalogHeader(
            title: 'Horario',
            subtitle: [
              if (week.relativeName != null) week.relativeName!,
              week.label,
            ].join(' · '),
            onAdd: () => _pickDate(context),
            addIcon: Icons.edit_calendar_outlined,
            addTooltip: 'Ir a una fecha',
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _onSwipe,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  WeekStrip(
                    week: week,
                    daysWithClasses: range == null
                        ? null
                        : {
                            for (final d in range.days)
                              if (d.classes.isNotEmpty)
                                DateTime(d.date.year, d.date.month, d.date.day),
                          },
                  ),
                  const SizedBox(height: 12),
                  _DayPanel(
                    week: week,
                    day: range?.days
                        .where((d) => isSameDay(d.date, week.selectedDay))
                        .firstOrNull,
                    body: switch (state.status) {
                      DetailStatus.error => SizedBox(
                        height: 320,
                        child: AppErrorState(
                          exception: state.error!,
                          onRetry: week.onRetry,
                        ),
                      ),
                      DetailStatus.success => null,
                      _ => const SizedBox(height: 200, child: AppLoading()),
                    },
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

/// The selected day: its title and count, today's next class, and the
/// timeline. [body] replaces the content while loading or on error.
class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.week, required this.day, this.body});

  final ScheduleWeek week;
  final DayScheduleEntity? day;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final day = this.day;
    // Server clock once loaded, so "today" doesn't depend on the phone.
    final isToday = day != null
        ? isSameDay(day.date, day.serverTime)
        : isSameDay(week.selectedDay, DateTime.now());
    final count = day?.classes.length;
    final next = isToday ? day?.nextClass : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.longDayMonth(week.selectedDay),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count != null)
                      Text(
                        switch (count) {
                          0 => 'Sin clases',
                          1 => '1 clase',
                          _ => '$count clases',
                        },
                        style: textTheme.bodyMedium?.copyWith(
                          color: textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isToday) ...[
                const SizedBox(width: 8),
                _TodayButton(onPressed: week.onToday),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (body != null)
            body!
          else if (day == null || day.classes.isEmpty)
            const DayNotice(
              icon: Icons.event_busy_outlined,
              title: 'Sin clases este día',
              message: 'No tienes clases programadas.',
            )
          else ...[
            if (next != null) ...[
              _NextClassBanner(
                scheduled: next,
                inProgress:
                    day.statusOf(next) == ScheduledClassStatus.inProgress,
              ),
              const SizedBox(height: 20),
            ],
            DayTimeline(day: day, isToday: isToday),
          ],
        ],
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.today_outlined, size: 18),
      label: const Text('Hoy'),
    );
  }
}

/// Today's class in progress, else the next to start.
class _NextClassBanner extends StatelessWidget {
  const _NextClassBanner({required this.scheduled, required this.inProgress});

  final ScheduledClassEntity scheduled;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = inProgress ? AppColors.success : AppColors.accentBlue;

    return Material(
      color: accent.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inProgress ? 'En curso' : 'Próxima clase',
                      style: textTheme.bodySmall?.copyWith(
                        color: inProgress ? accent : null,
                        fontWeight: inProgress ? FontWeight.w600 : null,
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
                      '${formatTimeRange(scheduled.startTime, scheduled.endTime)}'
                      '  ·  ${scheduled.courseLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}
