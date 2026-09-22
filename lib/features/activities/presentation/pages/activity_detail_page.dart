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

/// Grade capture (§99): edit every student's grade locally, then a single
/// sticky "Guardar calificaciones" commits the whole roster in one batch
/// request — same pattern as attendance's roster, instead of a per-row
/// save that made every row's spinner light up at once.
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

  Future<void> _save(List<StudentGradeEntity> students, double maximumScore) async {
    final entries = <({int studentId, double grade, String? comment})>[];
    final invalidNames = <String>[];
    for (final student in students) {
      final text = _controllerFor(student).text.trim();
      if (text.isEmpty) continue;
      final value = double.tryParse(text);
      if (value == null || value < 0 || value > maximumScore) {
        invalidNames.add(student.studentName);
        continue;
      }
      entries.add((studentId: student.studentId, grade: value, comment: null));
    }
    if (invalidNames.isNotEmpty) {
      context.showWarning(
        'Revisa la nota de ${invalidNames.join(', ')}: debe estar entre 0 y '
        '$maximumScore.',
      );
      return;
    }
    if (entries.isEmpty) {
      context.showWarning('Ingresa al menos una calificación.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<ActivitiesProvider>().saveGrades(
      widget.activityId,
      entries,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Calificaciones guardadas.');
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
    final gradesState = context.watch<ActivitiesProvider>().gradesState;
    final activity = state.data;
    final canSave = activity != null && gradesState.status == ViewStatus.success;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity?.name ?? 'Actividad'),
        actions: activity == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(activity),
                ),
              ],
      ),
      body: _buildBody(state, gradesState),
      bottomNavigationBar: !canSave
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Guardar calificaciones',
                  isLoading: _saving,
                  expand: true,
                  onPressed: () => _save(gradesState.items, activity.maximumScore),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(
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
          onRetry: () =>
              context.read<ActivitiesProvider>().loadDetail(widget.activityId),
        );
      case DetailStatus.success:
        final activity = state.data!;
        return Column(
          children: [
            AppPageHeader(
              title: activity.name,
              subtitle:
                  'Puntaje máximo: ${activity.maximumScore.toStringAsFixed(2)}',
            ),
            Expanded(child: _buildGrades(gradesState)),
          ],
        );
    }
  }

  Widget _buildGrades(ListViewState<StudentGradeEntity> state) {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                  controller: _controllerFor(student),
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
