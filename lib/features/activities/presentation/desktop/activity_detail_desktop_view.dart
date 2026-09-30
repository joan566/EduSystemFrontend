import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';
import '../shared/activity_grades_controller.dart';

/// Desktop: roster as a table (code, student, grade field) with delete and
/// save as header actions.
class ActivityDetailDesktopView extends StatelessWidget {
  const ActivityDetailDesktopView({super.key, required this.controller});

  final ActivityGradesController controller;

  @override
  Widget build(BuildContext context) {
    final activities = context.watch<ActivitiesProvider>();
    final state = activities.detail(controller.activityId);
    final gradesState = activities.grades(controller.activityId);
    final activity = state.data;
    final canSave =
        activity != null && gradesState.status == ViewStatus.success;
    final name = activity?.name ?? 'Actividad';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: name,
            subtitle: activity == null
                ? null
                : 'Puntaje máximo: ${activity.maximumScore.toStringAsFixed(2)}',
            breadcrumbs: ['Actividades', name],
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              if (activity != null)
                AppButton(
                  label: 'Eliminar',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.delete(context, activity),
                ),
              if (canSave)
                AppButton(
                  label: 'Guardar calificaciones',
                  icon: Icons.save_outlined,
                  isLoading: controller.saving,
                  onPressed: () => controller.save(
                    context,
                    gradesState.items,
                    activity.maximumScore,
                  ),
                ),
            ],
          ),
          Expanded(child: _buildBody(context, state, gradesState)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailViewState<ActivityEntity> state,
    ListViewState<StudentGradeEntity> gradesState,
  ) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ActivitiesProvider>().refreshDetail(
            controller.activityId,
          ),
        );
      case DetailStatus.success:
        return _buildGrades(context, gradesState);
    }
  }

  Widget _buildGrades(
    BuildContext context,
    ListViewState<StudentGradeEntity> state,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<ActivitiesProvider>().refreshGrades(
            controller.activityId,
          ),
        );
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay estudiantes en este curso',
          icon: Icons.people_alt_outlined,
        );
      case ViewStatus.success:
        return DesktopDataTable<StudentGradeEntity>(
          items: state.items,
          columns: [
            DesktopDataColumn(
              label: 'Código',
              cellBuilder: (student) => Text(student.studentCode),
            ),
            DesktopDataColumn(
              label: 'Estudiante',
              cellBuilder: (student) => Text(student.studentName),
            ),
            DesktopDataColumn(
              label: 'Nota',
              cellBuilder: (student) => SizedBox(
                width: 96,
                child: TextField(
                  controller: controller.controllerFor(student),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Nota',
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
