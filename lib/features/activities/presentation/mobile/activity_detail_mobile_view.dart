import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';
import '../shared/activity_grades_controller.dart';

/// Mobile: one card per student with an inline grade field, and a sticky
/// "Guardar calificaciones" button at the bottom.
class ActivityDetailMobileView extends StatelessWidget {
  const ActivityDetailMobileView({super.key, required this.controller});

  final ActivityGradesController controller;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesProvider>().detailState;
    final gradesState = context.watch<ActivitiesProvider>().gradesState;
    final activity = state.data;
    final canSave =
        activity != null && gradesState.status == ViewStatus.success;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity?.name ?? 'Actividad'),
        actions: activity == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.delete(context, activity),
                ),
              ],
      ),
      body: _buildBody(context, state, gradesState),
      bottomNavigationBar: !canSave
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Guardar calificaciones',
                  isLoading: controller.saving,
                  expand: true,
                  onPressed: () => controller.save(
                    context,
                    gradesState.items,
                    activity.maximumScore,
                  ),
                ),
              ),
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
          onRetry: () => context.read<ActivitiesProvider>().loadDetail(
            controller.activityId,
          ),
        );
      case DetailStatus.success:
        final activity = state.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Puntaje máximo: ${activity.maximumScore.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(child: _buildGrades(context, gradesState)),
          ],
        );
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
          onRetry: () => context.read<ActivitiesProvider>().loadGrades(
            controller.activityId,
          ),
        );
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay estudiantes en este curso',
          icon: Icons.people_alt_outlined,
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final student = state.items[index];
            return AppListTile(
              icon: Icons.person_outline,
              title: student.studentName,
              subtitle: 'Código: ${student.studentCode}',
              trailing: SizedBox(
                width: 72,
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
            );
          },
        );
    }
  }
}
