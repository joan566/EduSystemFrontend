import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/app_error_state.dart';
import '../../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../schedule/presentation/shared/class_schedule_actions.dart';
import '../../../../schedule/presentation/shared/class_schedule_form.dart';

/// "Clases": the class's weekly blocks, editable.
class ClassScheduleTab extends StatelessWidget {
  const ClassScheduleTab({super.key, required this.teachingPeriodId});

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
    final state = context.watch<ScheduleProvider>().classSchedules(
      teachingPeriodId,
    );

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const MobileListSkeleton(
          itemCount: 3,
          leading: SkeletonLeading.square,
          leadingSize: 40,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
        );
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ScheduleProvider>().refreshClassSchedules(
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
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  onTap: () => _openForm(context, initial: block),
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
            const SizedBox(height: 4),
            AppButton(
              label: 'Agregar bloque',
              icon: Icons.add,
              variant: AppButtonVariant.outlined,
              onPressed: () => _openForm(context),
            ),
          ],
        );
    }
  }
}
