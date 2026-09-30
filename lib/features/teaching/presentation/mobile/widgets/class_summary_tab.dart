import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../audit/domain/entities/audit_log_entity.dart';
import '../../../../audit/presentation/providers/audit_provider.dart';
import '../../../../audit/presentation/shared/audit_labels.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../domain/entities/teaching_period_entity.dart';
import '../../providers/teaching_provider.dart';
import '../../shared/progress_ring.dart';

/// "Resumen": evaluation counts and the class's next session.
class ClassSummaryTab extends StatelessWidget {
  const ClassSummaryTab({
    super.key,
    required this.period,
    required this.onOpenSchedule,
  });

  final TeachingPeriodEntity period;

  /// Switches to the "Clases" tab, where the weekly schedule is edited.
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressCard(teachingPeriodId: period.id),
        const SizedBox(height: 14),
        _NextSessionCard(period: period, onOpenSchedule: onOpenSchedule),
        const SizedBox(height: 14),
        _ClassActivityCard(teachingPeriodId: period.id),
      ],
    );
  }
}

/// "Progreso general": share of expected grades already recorded, beside
/// the evaluation counts.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodSummary(
      teachingPeriodId,
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = state.data;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: switch (state.status) {
        DetailStatus.error => Row(
          children: [
            Expanded(
              child: Text(
                'No pudimos cargar el progreso.',
                style: textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<TeachingProvider>()
                  .refreshPeriodSummary(teachingPeriodId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        DetailStatus.success => IntrinsicHeight(
          child: Row(
            children: [
              ProgressRing(percent: summary!.progressPercent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Progreso general',
                      style: textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    Text(
                      summary.expectedGrades == 0
                          ? 'Sin evaluaciones todavía'
                          : '${summary.registeredGrades} de '
                                '${summary.expectedGrades} notas registradas',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 20, color: colors.outline),
              // Sized by its content so the labels never wrap mid-word.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${summary.activityCount}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        summary.activityCount == 1
                            ? 'Actividad'
                            : 'Actividades',
                        style: textTheme.bodySmall,
                      ),
                      Text(
                        summary.examCount == 1
                            ? '+ 1 examen'
                            : '+ ${summary.examCount} exámenes',
                        style: textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        _ => const Skeleton(child: SkeletonRingSummary(ringSize: 72)),
      },
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.period, required this.onOpenSchedule});

  final TeachingPeriodEntity period;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>();
    final blocks = schedule.classSchedules(period.id);
    // Server clock when today's agenda is loaded, device clock otherwise.
    final now = schedule.today.data?.serverTime ?? DateTime.now();
    final textTheme = Theme.of(context).textTheme;

    return MobileSectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Próxima clase',
      linkLabel: 'Ver calendario',
      onLink: () => context.push(RoutePaths.schedule),
      child: switch (blocks.status) {
        ViewStatus.success => () {
          final next = nextClassOccurrence(
            blocks.items,
            now,
            lastDate: period.endDate,
          );
          if (next == null) {
            return Text(
              'No hay más clases programadas para este periodo.',
              style: textTheme.bodySmall,
            );
          }
          return _Occurrence(occurrence: next, period: period, now: now);
        }(),
        ViewStatus.empty => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta clase aún no tiene horario.',
              style: textTheme.bodyMedium,
            ),
            TextButton.icon(
              onPressed: onOpenSchedule,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar horario'),
            ),
          ],
        ),
        ViewStatus.error => Text(
          'No pudimos cargar el horario.',
          style: textTheme.bodySmall,
        ),
        _ => const SkeletonTileList(count: 1, trailingWidth: 56),
      },
    );
  }
}

class _Occurrence extends StatelessWidget {
  const _Occurrence({
    required this.occurrence,
    required this.period,
    required this.now,
  });

  final ClassOccurrence occurrence;
  final TeachingPeriodEntity period;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = occurrence.date;
    final block = occurrence.block;
    final inProgress = !now.isBefore(occurrence.start);

    return Row(
      children: [
        Container(
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                Formatters.shortWeekday(date),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
              Text(
                '${date.day}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _capitalized(Formatters.shortMonth(date)),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inProgress ? 'En curso ahora' : period.subjectName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: inProgress ? AppColors.success : null,
                ),
              ),
              Text(
                [
                  period.courseLabel,
                  formatTimeRange(block.startTime, block.endTime),
                  if (block.room != null) block.room!,
                ].join(' · '),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () =>
              context.push(RoutePaths.attendanceForClass(period.id)),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Asistencia'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

String _capitalized(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// This class's latest actions, from the audit trail scoped to it.
class _ClassActivityCard extends StatelessWidget {
  const _ClassActivityCard({required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().classLogs(teachingPeriodId);
    final textTheme = Theme.of(context).textTheme;

    return MobileSectionCard(
      icon: Icons.history_rounded,
      title: 'Actividad reciente',
      linkLabel: 'Ver todo',
      onLink: () => context.push(RoutePaths.auditForClass(teachingPeriodId)),
      child: switch (state.status) {
        ViewStatus.success => Column(
          children: [
            for (final (i, log) in state.items.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _ActivityRow(log: log),
            ],
          ],
        ),
        ViewStatus.empty => Text(
          'Aún no hay actividad en esta clase.',
          style: textTheme.bodySmall,
        ),
        ViewStatus.error => Row(
          children: [
            Expanded(
              child: Text(
                'No pudimos cargar la actividad.',
                style: textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => context.read<AuditProvider>().refreshClassLogs(
                teachingPeriodId,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        _ => const SkeletonTileList(
          leading: SkeletonLeading.circle,
          leadingSize: 32,
        ),
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = log.isSuccess
        ? auditActionAccent(log.action)
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          TintedIcon(
            icon: log.isSuccess ? auditActionIcon(log.action) : Icons.error,
            color: color,
            size: 38,
            circle: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditActionLabel(log.action),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  auditEntityLabel(log),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.relativeTime(log.createdAt),
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
