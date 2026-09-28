import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/schedule_entities.dart';
import '../providers/schedule_provider.dart';
import '../shared/schedule_week.dart';
import '../shared/schedule_widgets.dart';

/// Mobile: the week as a vertical agenda, day by day.
class ScheduleMobileView extends StatelessWidget {
  const ScheduleMobileView({super.key, required this.week});

  final ScheduleWeek week;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().calendar;

    return Scaffold(
      body: Column(
        children: [
          MobilePageHeader(
            title: 'Horario',
            subtitle: week.label,
            actions: [
              IconButton(
                tooltip: 'Semana anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: week.onPrevious,
              ),
              if (!week.isCurrent)
                IconButton(
                  tooltip: 'Esta semana',
                  icon: const Icon(Icons.today_outlined),
                  onPressed: week.onToday,
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
              DetailStatus.success => ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [for (final day in state.data!.days) _Day(day: day)],
              ),
              _ => const AppLoading(),
            },
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day});

  final DayScheduleEntity day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isToday = isSameDay(day.date, day.serverTime);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                Formatters.longDayMonth(day.date),
                style: textTheme.titleMedium?.copyWith(
                  color: isToday ? AppColors.accentBlue : null,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text(
                  'Hoy',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (day.classes.isEmpty)
            Text('Sin clases', style: textTheme.bodySmall)
          else
            for (final c in day.classes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ClassRow(
                  scheduled: c,
                  status: isToday ? day.statusOf(c) : null,
                ),
              ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.scheduled, required this.status});

  final ScheduledClassEntity scheduled;

  /// Only for today's classes.
  final ScheduledClassStatus? status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = subjectAccent(scheduled.subjectId);
    final details = [
      scheduled.courseLabel,
      if (scheduled.room != null) scheduled.room!,
    ].join(' · ');

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RoutePaths.teachingPeriodDetail(scheduled.teachingPeriodId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduled.startTime.format(),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      scheduled.endTime.format(),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  subjectIcon(scheduled.subjectName),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduled.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (status != null) ScheduleStatusChip(status: status!),
            ],
          ),
        ),
      ),
    );
  }
}
