import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../schedule/presentation/shared/schedule_widgets.dart';
import '../../shared/dashboard_error_notice.dart';

/// "Hoy": the day's classes as a timeline with statuses (server clock).
class TodayCard extends StatelessWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final state = provider.today;
    final today = state.data;

    return DesktopSectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Hoy',
      subtitle: Formatters.longDayMonth(today?.date ?? DateTime.now()),
      linkLabel: 'Ver calendario',
      onLink: () => context.go(RoutePaths.schedule),
      child: switch (state.status) {
        DetailStatus.error => DashboardErrorNotice(
          onRetry: () => context.read<ScheduleProvider>().refreshToday(),
        ),
        DetailStatus.success when today!.classes.isNotEmpty => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in today.classes.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _TimelineRow(
                scheduled: c,
                status: today.statusOf(c),
                isFirst: i == 0,
                isLast: i == today.classes.length - 1,
              ),
            ],
            const SizedBox(height: 12),
            _FooterButton(
              label: 'Ver todas las clases',
              onTap: () => context.go(RoutePaths.teaching),
            ),
          ],
        ),
        DetailStatus.success => _Empty(
          hasAnySchedule:
              provider.week.data?.occurrencesByTeachingPeriod.isNotEmpty ??
              false,
        ),
        _ => const SkeletonTileList(
          leading: SkeletonLeading.circle,
          leadingSize: 10,
          trailingWidth: 90,
        ),
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.scheduled,
    required this.status,
    required this.isFirst,
    required this.isLast,
  });

  final ScheduledClassEntity scheduled;
  final ScheduledClassStatus status;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final lineColor = colors.outline;
    final finished = status == ScheduledClassStatus.finished;

    return InkWell(
      onTap: () => context.push(
        RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: finished ? 0.6 : 1,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Timeline rail: a status-colored node on a connecting line.
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheduleStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : lineColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  formatTimeRange(scheduled.startTime, scheduled.endTime),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TintedIcon(
                  icon: subjectIcon(scheduled.subjectName),
                  color: subjectAccent(scheduled.subjectId),
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      scheduled.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        scheduled.courseLabel,
                        scheduled.academicPeriodName,
                        if (scheduled.room != null) scheduled.room!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ScheduleStatusChip(status: status),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentBlue.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty day; when no class has a schedule at all, point to where it's set
/// up instead of implying a free day.
class _Empty extends StatelessWidget {
  const _Empty({required this.hasAnySchedule});

  final bool hasAnySchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const TintedIcon(
          icon: Icons.event_available_outlined,
          color: AppColors.accentBlue,
          size: 44,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasAnySchedule
                    ? 'No tienes clases hoy.'
                    : 'Aún no has configurado el horario de tus clases.',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                hasAnySchedule
                    ? 'Revisa el resto de la semana en tu calendario.'
                    : 'Abre una clase y agrega sus días y horas para verla aquí.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!hasAnySchedule)
          TextButton(
            onPressed: () => context.go(RoutePaths.teaching),
            child: const Text('Ir a mis clases'),
          ),
      ],
    );
  }
}
