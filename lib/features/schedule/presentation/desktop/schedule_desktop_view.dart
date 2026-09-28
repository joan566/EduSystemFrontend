import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/schedule_entities.dart';
import '../providers/schedule_provider.dart';
import '../shared/schedule_week.dart';
import '../shared/schedule_widgets.dart';

/// Desktop: the week as a seven-column grid, one column per day.
class ScheduleDesktopView extends StatelessWidget {
  const ScheduleDesktopView({super.key, required this.week});

  final ScheduleWeek week;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().calendar;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: 'Horario',
            subtitle: week.label,
            actions: [
              IconButton(
                tooltip: 'Semana anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: week.onPrevious,
              ),
              AppButton(
                label: 'Esta semana',
                variant: AppButtonVariant.outlined,
                onPressed: week.isCurrent ? null : week.onToday,
              ),
              IconButton(
                tooltip: 'Semana siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: week.onNext,
              ),
            ],
          ),
          Expanded(
            child: switch (state.status) {
              DetailStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: week.onRetry,
              ),
              DetailStatus.success => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, day) in state.data!.days.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _DayColumn(day: day)),
                    ],
                  ],
                ),
              ),
              _ => const AppLoading(),
            },
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day});

  final DayScheduleEntity day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isToday = isSameDay(day.date, day.serverTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.accentBlue.withValues(alpha: 0.1)
                : colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                Formatters.weekdayName(day.date.weekday),
                style: textTheme.labelMedium?.copyWith(
                  color: isToday ? AppColors.accentBlue : null,
                ),
              ),
              Text(
                '${day.date.day}',
                style: textTheme.titleLarge?.copyWith(
                  color: isToday ? AppColors.accentBlue : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (day.classes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sin clases',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          for (final c in day.classes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ClassBlock(
                scheduled: c,
                status: isToday ? day.statusOf(c) : null,
              ),
            ),
      ],
    );
  }
}

class _ClassBlock extends StatelessWidget {
  const _ClassBlock({required this.scheduled, required this.status});

  final ScheduledClassEntity scheduled;
  final ScheduledClassStatus? status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = subjectAccent(scheduled.subjectId);

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatTimeRange(scheduled.startTime, scheduled.endTime),
                style: textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              Text(
                scheduled.subjectName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                [
                  scheduled.courseLabel,
                  if (scheduled.room != null) scheduled.room!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              if (status != null) ...[
                const SizedBox(height: 6),
                ScheduleStatusChip(status: status!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
