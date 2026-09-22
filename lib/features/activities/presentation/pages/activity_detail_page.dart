import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final int activityId;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ActivitiesProvider>().loadDetail(widget.activityId),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(StudentGradeEntity student) {
    return _controllers.putIfAbsent(
      student.studentId,
      () =>
          TextEditingController(text: student.grade?.toStringAsFixed(2) ?? ''),
    );
  }

  Future<void> _saveGrade(
    StudentGradeEntity student,
    double maximumScore,
  ) async {
    final text = _controllerFor(student).text.trim();
    final value = double.tryParse(text);
    if (value == null || value < 0 || value > maximumScore) {
      context.showWarning('Ingresa una nota entre 0 y $maximumScore.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<ActivitiesProvider>().saveGrade(
      widget.activityId,
      student.studentId,
      value,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Calificación guardada.');
    }
  }

  Future<void> _delete(ActivityEntity activity) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar actividad',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<ActivitiesProvider>().delete(
      activity.id,
      teachingPeriodId: activity.teachingPeriodId,
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivitiesProvider>().detailState;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.data?.name ?? 'Actividad'),
        actions: state.data == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(state.data!),
                ),
              ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(DetailViewState<ActivityEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ActivitiesProvider>().loadDetail(widget.activityId),
        );
      case DetailStatus.success:
        final activity = state.data!;
        final gradesState = context.watch<ActivitiesProvider>().gradesState;
        return Column(
          children: [
            AppPageHeader(
              title: activity.name,
              subtitle:
                  'Puntaje máximo: ${activity.maximumScore.toStringAsFixed(2)}',
            ),
            Expanded(child: _buildGrades(gradesState, activity)),
          ],
        );
    }
  }

  Widget _buildGrades(
    ListViewState<StudentGradeEntity> state,
    ActivityEntity activity,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<ActivitiesProvider>().loadGrades(widget.activityId),
        );
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay estudiantes en este curso',
          icon: Icons.people_alt_outlined,
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final student = state.items[index];
            return AppListTile(
              icon: Icons.person_outline,
              title: student.studentName,
              subtitle: 'Código: ${student.studentCode}',
              trailing: SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controllerFor(student),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Nota',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Guardar',
                      isLoading: _saving,
                      onPressed: () =>
                          _saveGrade(student, activity.maximumScore),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }
}
