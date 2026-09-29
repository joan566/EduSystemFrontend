import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../schedule/presentation/shared/class_schedule_actions.dart';
import '../../../../schedule/presentation/shared/class_schedule_form.dart';
import '../../../domain/entities/teaching_period_entity.dart';

/// "Horario": the class's weekly blocks on an hour grid, placed at their
/// real times. Click a block to edit or delete it.
class ClassWeekGrid extends StatelessWidget {
  const ClassWeekGrid({super.key, required this.period});

  final TeachingPeriodEntity period;

  static const _hourHeight = 56.0;
  static const _timeColumnWidth = 52.0;

  Future<void> _openForm(
    BuildContext context, {
    ClassScheduleEntity? initial,
  }) async {
    final data = await showDesktopDialog<ClassScheduleFormResult>(
      context,
      child: ClassScheduleForm(initial: initial),
    );
    if (data == null || !context.mounted) return;
    await ClassScheduleActions.save(
      context,
      teachingPeriodId: period.id,
      initial: initial,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().classSchedules(period.id);

    return DesktopSectionCard(
      icon: Icons.calendar_view_week_outlined,
      title: 'Horario semanal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Agregar bloque',
              icon: Icons.add,
              onPressed: () => _openForm(context),
            ),
          ),
          const SizedBox(height: 16),
          switch (state.status) {
            ViewStatus.error => AppErrorState(
              exception: state.error!,
              onRetry: () => context
                  .read<ScheduleProvider>()
                  .loadClassSchedules(period.id),
            ),
            ViewStatus.empty => const AppEmptyState(
              title: 'Sin horario',
              message:
                  'Agrega los días y horas de esta clase para verla en "Hoy" '
                  'y en tu calendario.',
              icon: Icons.schedule_outlined,
            ),
            ViewStatus.success => _Grid(
              blocks: state.items,
              period: period,
              onEdit: (block) => _openForm(context, initial: block),
              onDelete: (block) => ClassScheduleActions.delete(
                context,
                teachingPeriodId: period.id,
                block: block,
              ),
            ),
            _ => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          },
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.blocks,
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ClassScheduleEntity> blocks;
  final TeachingPeriodEntity period;
  final ValueChanged<ClassScheduleEntity> onEdit;
  final ValueChanged<ClassScheduleEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const hourHeight = ClassWeekGrid._hourHeight;

    // Monday–Friday always; weekend only when a block falls there.
    final days = [
      for (var d = 1; d <= 7; d++)
        if (d <= 5 || blocks.any((b) => b.dayOfWeek == d)) d,
    ];
    // Hour window around the blocks, at least 7:00–13:00.
    final firstHour = blocks
        .map((b) => b.startTime.hour)
        .fold(7, (a, b) => a < b ? a : b);
    final lastHour = blocks
        .map((b) => b.endTime.minute > 0 ? b.endTime.hour + 1 : b.endTime.hour)
        .fold(13, (a, b) => a > b ? a : b);
    final hours = lastHour - firstHour;
    final today = DateTime.now().weekday;
    final color = subjectAccent(period.subjectId);

    return Padding(
      // Room for the last hour label, which sits on the bottom line.
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // Day headers.
          Row(
            children: [
              const SizedBox(width: ClassWeekGrid._timeColumnWidth),
              for (final d in days)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: d == today
                          ? AppColors.accentBlue.withValues(alpha: 0.1)
                          : colors.surfaceContainerHighest.withValues(
                              alpha: 0.45,
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Formatters.weekdayName(d),
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: d == today ? AppColors.accentBlue : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: hours * hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hour labels.
                SizedBox(
                  width: ClassWeekGrid._timeColumnWidth,
                  // Labels sit centered on their hour line, so the first one
                  // extends above the grid.
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var h = 0; h <= hours; h++)
                        Positioned(
                          top: h * hourHeight - 7,
                          left: 0,
                          child: Text(
                            '${(firstHour + h).toString().padLeft(2, '0')}:00',
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final d in days)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Stack(
                        children: [
                          // Hour lines.
                          for (var h = 0; h <= hours; h++)
                            Positioned(
                              top: h * hourHeight,
                              left: 0,
                              right: 0,
                              child: Divider(
                                height: 1,
                                color: colors.outline.withValues(alpha: 0.6),
                              ),
                            ),
                          for (final block in blocks.where(
                            (b) => b.dayOfWeek == d,
                          ))
                            Positioned(
                              top:
                                  (block.startTime.minutesOfDay -
                                      firstHour * 60) *
                                  hourHeight /
                                  60,
                              height:
                                  (block.endTime.minutesOfDay -
                                      block.startTime.minutesOfDay) *
                                  hourHeight /
                                  60,
                              left: 0,
                              right: 0,
                              child: _Block(
                                block: block,
                                color: color,
                                onEdit: () => onEdit(block),
                                onDelete: () => onDelete(block),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassScheduleEntity block;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: PopupMenuButton<bool>(
        tooltip: 'Editar o eliminar',
        onSelected: (edit) => edit ? onEdit() : onDelete(),
        itemBuilder: (context) => const [
          PopupMenuItem(value: true, child: Text('Editar bloque')),
          PopupMenuItem(value: false, child: Text('Eliminar bloque')),
        ],
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
          // Short blocks clip their text instead of overflowing.
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTimeRange(block.startTime, block.endTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(color: color),
                ),
                if (block.room != null)
                  Text(
                    block.room!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
