import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../schedule/domain/entities/schedule_entities.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/presentation/shared/class_schedule_actions.dart';
import '../../../schedule/presentation/shared/class_schedule_form.dart';
import '../providers/teaching_provider.dart';
import '../shared/teaching_period_info.dart';

/// Mobile: class card, then its weekly blocks as cards; FAB adds a block.
class TeachingPeriodDetailMobileView extends StatelessWidget {
  const TeachingPeriodDetailMobileView({
    super.key,
    required this.teachingPeriodId,
  });

  final int teachingPeriodId;

  Future<void> _openForm(
    BuildContext context, {
    ClassScheduleEntity? initial,
  }) async {
    final data = await showMobileForm<ClassScheduleFormResult>(
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

    return Scaffold(
      appBar: AppBar(title: Text(period?.subjectName ?? 'Clase')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Bloque'),
      ),
      body: switch (state.status) {
        DetailStatus.error => AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<TeachingProvider>().loadPeriodDetail(
            teachingPeriodId,
          ),
        ),
        _ when period == null => const AppLoading(),
        _ => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            AppCard(child: TeachingPeriodInfo(period: period)),
            const SizedBox(height: 20),
            Text(
              'Horario semanal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Blocks(
              teachingPeriodId: teachingPeriodId,
              onEdit: (block) => _openForm(context, initial: block),
              onAdd: () => _openForm(context),
            ),
          ],
        ),
      },
    );
  }
}

class _Blocks extends StatelessWidget {
  const _Blocks({
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
        return Column(
          children: [
            for (final block in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppListTile(
                  icon: Icons.schedule_outlined,
                  title:
                      '${Formatters.weekdayName(block.dayOfWeek)} · '
                      '${formatTimeRange(block.startTime, block.endTime)}',
                  subtitle: block.room,
                  onTap: () => onEdit(block),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => ClassScheduleActions.delete(
                      context,
                      teachingPeriodId: teachingPeriodId,
                      block: block,
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }
}
