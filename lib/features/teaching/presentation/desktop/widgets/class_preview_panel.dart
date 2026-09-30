import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/cache/synced_data_state.dart';
import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../domain/entities/teaching_period_entity.dart';
import '../../providers/teaching_provider.dart';
import '../../shared/class_lookup.dart';
import '../../shared/progress_ring.dart';
import 'classes_table.dart';

/// Right-hand preview of the selected row: the class at a glance and its
/// shortcuts, without leaving the list.
class ClassPreviewPanel extends StatelessWidget {
  const ClassPreviewPanel({
    super.key,
    required this.row,
    required this.academicPeriod,
    required this.onCreateClass,
  });

  final ClassRowData? row;
  final AcademicPeriodEntity? academicPeriod;
  final VoidCallback onCreateClass;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = this.row;
    final period = row?.period;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: row == null
          ? const _Placeholder(
              icon: Icons.touch_app_outlined,
              title: 'Selecciona una clase',
              message:
                  'Haz clic en una fila para ver su resumen aquí. Doble clic '
                  'o Enter la abre.',
            )
          : period == null
          ? _NoClass(
              row: row,
              academicPeriod: academicPeriod,
              onCreate: onCreateClass,
            )
          : _ClassPreview(
              key: ValueKey(period.id),
              period: period,
              weeklySessions: row.weeklySessions,
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintedIcon(icon: icon, color: AppColors.accentBlue, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _NoClass extends StatelessWidget {
  const _NoClass({
    required this.row,
    required this.academicPeriod,
    required this.onCreate,
  });

  final ClassRowData row;
  final AcademicPeriodEntity? academicPeriod;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final a = row.assignment;
    final periodName = academicPeriod?.name;
    return _Placeholder(
      icon: subjectIcon(a.subjectName),
      title: '${a.subjectName} — ${a.gradeName} ${a.groupName}',
      message: periodName == null
          ? 'Esta asignación aún no tiene clases por periodo.'
          : 'No tiene clase en $periodName. Créala para programar su '
                'horario, tomar asistencia y evaluar.',
      action: periodName == null
          ? null
          : FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Crear clase en $periodName'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
              ),
            ),
    );
  }
}

/// Loads the class's summary and weekly blocks the first time it's shown.
class _ClassPreview extends StatefulWidget {
  const _ClassPreview({
    super.key,
    required this.period,
    required this.weeklySessions,
  });

  final TeachingPeriodEntity period;
  final int? weeklySessions;

  @override
  State<_ClassPreview> createState() => _ClassPreviewState();
}

class _ClassPreviewState extends State<_ClassPreview>
    with SyncedDataState<_ClassPreview> {
  /// Classes already previewed come from memory.
  @override
  void ensureData() {
    final id = widget.period.id;
    context.read<TeachingProvider>().ensurePeriodSummary(id);
    context.read<ScheduleProvider>().ensureClassSchedules(id);
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final summary = context.watch<TeachingProvider>().periodSummary(period.id);
    final schedule = context.watch<ScheduleProvider>();
    final blocks = schedule.classSchedules(period.id);
    final now = schedule.today.data?.serverTime ?? DateTime.now();
    final next = blocks.status == ViewStatus.success
        ? nextClassOccurrence(blocks.items, now, lastDate: period.endDate)
        : null;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = switch (classPeriodStatus(
      period,
      DateTime.now(),
    )) {
      ClassPeriodStatus.active => ('Clase activa', AppColors.accentGreen),
      ClassPeriodStatus.upcoming => ('Próxima a iniciar', AppColors.accentBlue),
      ClassPeriodStatus.finished => ('Finalizada', AppColors.textDisabled),
    };

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Compact brand header.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primaryMedium],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  subjectIcon(period.subjectName),
                  color: subjectAccent(period.subjectId),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${period.subjectName} — ${period.courseLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      period.academicPeriodName,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grading progress.
              switch (summary.status) {
                DetailStatus.success => Row(
                  children: [
                    ProgressRing(
                      percent: summary.data!.progressPercent,
                      size: 76,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progreso general',
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            summary.data!.expectedGrades == 0
                                ? 'Sin evaluaciones todavía'
                                : '${summary.data!.registeredGrades} de '
                                      '${summary.data!.expectedGrades} notas '
                                      'registradas',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                DetailStatus.error => Text(
                  'No pudimos cargar el progreso.',
                  style: textTheme.bodySmall,
                ),
                _ => const Skeleton(
                  child: SkeletonRingSummary(ringSize: 76, stats: 0),
                ),
              },
              const SizedBox(height: 18),
              // Key figures.
              Row(
                children: [
                  _Figure(value: '${period.studentCount}', label: 'Alumnos'),
                  _Figure(
                    value: widget.weeklySessions?.toString() ?? '—',
                    label: 'Clases/sem',
                  ),
                  _Figure(
                    value: summary.data?.activityCount.toString() ?? '—',
                    label: 'Actividades',
                  ),
                  _Figure(
                    value: summary.data?.examCount.toString() ?? '—',
                    label: 'Exámenes',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: colors.outline),
              const SizedBox(height: 16),
              Text('Próxima clase', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(switch (blocks.status) {
                ViewStatus.empty => 'Sin horario configurado',
                ViewStatus.success when next == null =>
                  'No hay más clases en este periodo',
                ViewStatus.success =>
                  '${Formatters.longDayMonth(next!.date)} · '
                      '${formatTimeRange(next.block.startTime, next.block.endTime)}'
                      '${next.block.room == null ? '' : ' · ${next.block.room}'}',
                ViewStatus.error => 'No pudimos cargar el horario',
                _ => 'Cargando…',
              }, style: textTheme.bodyMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.push(RoutePaths.teachingPeriodDetail(period.id)),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Abrir clase'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Shortcut(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Asistencia',
                    onTap: () =>
                        context.push(RoutePaths.attendanceForClass(period.id)),
                  ),
                  const SizedBox(width: 8),
                  _Shortcut(
                    icon: Icons.description_outlined,
                    label: 'Examen',
                    onTap: () =>
                        context.push(RoutePaths.examCreateForClass(period.id)),
                  ),
                  const SizedBox(width: 8),
                  _Shortcut(
                    icon: Icons.edit_note_outlined,
                    label: 'Actividad',
                    onTap: () =>
                        context.push(RoutePaths.activitiesForClass(period.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          foregroundColor: AppColors.accentBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
