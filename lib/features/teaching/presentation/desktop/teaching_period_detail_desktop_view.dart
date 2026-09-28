import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../schedule/domain/entities/schedule_entities.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/presentation/shared/class_schedule_actions.dart';
import '../../../schedule/presentation/shared/class_schedule_form.dart';
import '../providers/teaching_provider.dart';
import '../shared/teaching_period_info.dart';

/// Desktop: class card on the left, the weekly blocks as a table on the
/// right.
class TeachingPeriodDetailDesktopView extends StatelessWidget {
  const TeachingPeriodDetailDesktopView({
    super.key,
    required this.teachingPeriodId,
  });

  final int teachingPeriodId;

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
      teachingPeriodId: teachingPeriodId,
      initial: initial,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodDetail;
    final period = state.data?.id == teachingPeriodId ? state.data : null;
    final title = period?.subjectName ?? 'Clase';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: title,
            subtitle: period == null
                ? null
                : '${period.courseLabel} · ${period.academicPeriodName}',
            breadcrumbs: ['Clases', title],
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              AppButton(
                label: 'Agregar bloque',
                icon: Icons.add,
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          Expanded(
            child: switch (state.status) {
              DetailStatus.error => AppErrorState(
                exception: state.error!,
                onRetry: () => context
                    .read<TeachingProvider>()
                    .loadPeriodDetail(teachingPeriodId),
              ),
              _ when period == null => const AppLoading(),
              _ => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 340,
                      child: AppCard(child: TeachingPeriodInfo(period: period)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Horario semanal',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _BlocksTable(
                              teachingPeriodId: teachingPeriodId,
                              onEdit: (block) =>
                                  _openForm(context, initial: block),
                              onAdd: () => _openForm(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _BlocksTable extends StatelessWidget {
  const _BlocksTable({
    required this.teachingPeriodId,
    required this.onEdit,
    required this.onAdd,
  });

  final int teachingPeriodId;
  final ValueChanged<ClassScheduleEntity> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().classSchedules(
      teachingPeriodId,
    );

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const Padding(padding: EdgeInsets.all(24), child: AppLoading());
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ScheduleProvider>().loadClassSchedules(
            teachingPeriodId,
          ),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'Sin horario',
          message:
              'Agrega los días y horas de esta clase para verla en "Hoy" y en '
              'tu calendario.',
          icon: Icons.schedule_outlined,
          actionLabel: 'Agregar bloque',
          onAction: onAdd,
        );
      case ViewStatus.success:
        return DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Día')),
            DataColumn(label: Text('Horario')),
            DataColumn(label: Text('Salón')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: [
            for (final block in state.items)
              DataRow(
                onSelectChanged: (_) => onEdit(block),
                cells: [
                  DataCell(Text(Formatters.weekdayName(block.dayOfWeek))),
                  DataCell(
                    Text(formatTimeRange(block.startTime, block.endTime)),
                  ),
                  DataCell(Text(block.room ?? '—')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => onEdit(block),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => ClassScheduleActions.delete(
                            context,
                            teachingPeriodId: teachingPeriodId,
                            block: block,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
    }
  }
}
