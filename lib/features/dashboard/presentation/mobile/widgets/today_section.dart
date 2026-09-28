import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../schedule/presentation/shared/schedule_widgets.dart';
import '../../shared/dashboard_error_notice.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import 'mobile_dashboard_section.dart';

/// "Hoy": the next (or current) class highlighted, then the day's classes
/// as a timeline, and a link to the full calendar. Statuses use the
/// server's clock, not the phone's.
class TodaySection extends StatelessWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final state = provider.today;
    final today = state.data;

    return MobileDashboardSection(
      icon: Icons.calendar_month_outlined,
      title: 'Hoy',
      subtitle: Formatters.longDayMonth(today?.date ?? DateTime.now()),
      child: switch (state.status) {
        DetailStatus.error => DashboardErrorNotice(
          onRetry: () => context.read<ScheduleProvider>().loadToday(),
        ),
        DetailStatus.success when today!.classes.isNotEmpty => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (today.nextClass case final next?) ...[
              _NextClassCard(
                scheduled: next,
                inProgress:
                    today.statusOf(next) == ScheduledClassStatus.inProgress,
              ),
              const SizedBox(height: 8),
            ],
            for (final c in today.classes)
              _TimelineRow(scheduled: c, status: today.statusOf(c)),
            const SizedBox(height: 8),
            const _CalendarLink(),
          ],
        ),
        DetailStatus.success => _NoClassesToday(
          hasAnySchedule:
              (provider.week.data?.occurrencesByTeachingPeriod.isNotEmpty ??
              false),
        ),
        _ => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      },
    );
  }
}

void _openClass(BuildContext context, ScheduledClassEntity scheduled) =>
    context.push(RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId));

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.scheduled, required this.inProgress});

  final ScheduledClassEntity scheduled;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openClass(context, scheduled),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                TintedIcon(
                  icon: subjectIcon(scheduled.subjectName),
                  color: subjectAccent(scheduled.subjectId),
                  size: 48,
                  solid: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inProgress ? 'En curso ahora' : 'Tu próxima clase',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scheduled.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          scheduled.courseLabel,
                          formatTimeRange(
                            scheduled.startTime,
                            scheduled.endTime,
                          ),
                          if (scheduled.room != null) scheduled.room!,
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _openClass(context, scheduled),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ver clase'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.scheduled, required this.status});

  final ScheduledClassEntity scheduled;
  final ScheduledClassStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final finished = status == ScheduledClassStatus.finished;

    return InkWell(
      onTap: () => _openClass(context, scheduled),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: finished ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheduleStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  formatTimeRange(scheduled.startTime, scheduled.endTime),
                  style: textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
              ),
              TintedIcon(
                icon: subjectIcon(scheduled.subjectName),
                color: subjectAccent(scheduled.subjectId),
                size: 34,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduled.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(scheduled.courseLabel, style: textTheme.bodySmall),
                  ],
                ),
              ),
              ScheduleStatusChip(status: status),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLink extends StatelessWidget {
  const _CalendarLink();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentBlue.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(RoutePaths.schedule),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ver calendario',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty day. When no class has a schedule at all, point the teacher to
/// where schedules are set up instead of implying a free day.
class _NoClassesToday extends StatelessWidget {
  const _NoClassesToday({required this.hasAnySchedule});

  final bool hasAnySchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hasAnySchedule
              ? 'No tienes clases hoy.'
              : 'Aún no has configurado el horario de tus clases.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          hasAnySchedule
              ? 'Revisa el resto de la semana en tu calendario.'
              : 'Abre una clase y agrega sus días y horas para verla aquí.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        hasAnySchedule
            ? const _CalendarLink()
            : Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(RoutePaths.teaching),
                  icon: const Icon(Icons.schedule_outlined, size: 18),
                  label: const Text('Ir a mis clases'),
                ),
              ),
      ],
    );
  }
}
