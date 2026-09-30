import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../subjects/presentation/providers/subjects_provider.dart';
import '../../../domain/entities/teaching_period_entity.dart';
import '../../providers/teaching_provider.dart';
import '../../shared/class_lookup.dart';
import '../../shared/progress_ring.dart';

/// The class detail's always-visible side column: grading progress, next
/// session and the class's facts.
List<Widget> classDetailRailCards(TeachingPeriodEntity period) => [
  _ProgressCard(period: period),
  _NextSessionCard(period: period),
  _FactsCard(period: period),
];

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.period});

  final TeachingPeriodEntity period;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodSummary(period.id);
    final summary = state.data;
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.insights_outlined,
      title: 'Progreso general',
      child: switch (state.status) {
        DetailStatus.success => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProgressRing(percent: summary!.progressPercent, size: 92),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.registeredGrades}'
                        '${summary.expectedGrades == 0 ? '' : ' / ${summary.expectedGrades}'}',
                        style: textTheme.headlineLarge?.copyWith(fontSize: 24),
                      ),
                      Text(
                        summary.expectedGrades == 0
                            ? 'Sin evaluaciones todavía'
                            : 'notas registradas',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(value: summary.activityCount, label: 'Actividades'),
                _Stat(value: summary.examCount, label: 'Exámenes'),
                _Stat(value: summary.studentCount, label: 'Alumnos'),
              ],
            ),
          ],
        ),
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
                  .refreshPeriodSummary(period.id),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        _ => const Skeleton(child: SkeletonRingSummary()),
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.period});

  final TeachingPeriodEntity period;

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>();
    final blocks = schedule.classSchedules(period.id);
    final now = schedule.today.data?.serverTime ?? DateTime.now();
    final next = blocks.status == ViewStatus.success
        ? nextClassOccurrence(blocks.items, now, lastDate: period.endDate)
        : null;
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.event_outlined,
      title: 'Próxima clase',
      linkLabel: 'Calendario',
      onLink: () => context.push(RoutePaths.schedule),
      child: next == null
          ? Text(switch (blocks.status) {
              ViewStatus.empty =>
                'Sin horario. Agrégalo en la pestaña Horario.',
              ViewStatus.success => 'No hay más clases en este periodo.',
              ViewStatus.error => 'No pudimos cargar el horario.',
              _ => 'Cargando…',
            }, style: textTheme.bodySmall)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            Formatters.shortWeekday(next.date),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.accentBlue,
                            ),
                          ),
                          Text(
                            '${next.date.day}',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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
                            !now.isBefore(next.start)
                                ? 'En curso ahora'
                                : Formatters.longDayMonth(next.date),
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            [
                              formatTimeRange(
                                next.block.startTime,
                                next.block.endTime,
                              ),
                              if (next.block.room != null) next.block.room!,
                            ].join(' · '),
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(RoutePaths.attendanceForClass(period.id)),
                  icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                  label: const Text('Registrar asistencia'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.period});

  final TeachingPeriodEntity period;

  @override
  Widget build(BuildContext context) {
    final subject = context
        .watch<SubjectsProvider>()
        .state
        .items
        .where((s) => s.id == period.subjectId)
        .firstOrNull;
    final status = switch (classPeriodStatus(period, DateTime.now())) {
      ClassPeriodStatus.active => 'En curso',
      ClassPeriodStatus.upcoming => 'Aún no inicia',
      ClassPeriodStatus.finished => 'Finalizada',
    };

    return DesktopSectionCard(
      icon: Icons.info_outline,
      title: 'Datos de la clase',
      child: Column(
        children: [
          _Fact(label: 'Materia', value: period.subjectName),
          if (subject?.description != null)
            _Fact(label: 'Área', value: subject!.description!),
          _Fact(label: 'Curso', value: period.courseLabel),
          _Fact(label: 'Periodo', value: period.academicPeriodName),
          _Fact(
            label: 'Fechas',
            value:
                '${Formatters.shortDayMonth(period.startDate)} – '
                '${Formatters.shortDayMonth(period.endDate)} '
                '${period.endDate.year}',
          ),
          _Fact(label: 'Estado', value: status),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: textTheme.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
