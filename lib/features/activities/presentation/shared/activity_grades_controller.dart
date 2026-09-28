import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/activity_entity.dart';
import '../providers/activities_provider.dart';

/// Grade capture state for one activity (§99): every student's grade is
/// edited locally, then [save] commits the whole roster in one batch.
/// Owned by the page entry point so edits survive a mobile <-> desktop
/// switch; both views render from it.
class ActivityGradesController extends ChangeNotifier {
  ActivityGradesController(this.activityId);

  final int activityId;
  final Map<int, TextEditingController> _controllers = {};

  bool _saving = false;
  bool get saving => _saving;

  TextEditingController controllerFor(StudentGradeEntity student) {
    return _controllers.putIfAbsent(
      student.studentId,
      () =>
          TextEditingController(text: student.grade?.toStringAsFixed(2) ?? ''),
    );
  }

  Future<void> save(
    BuildContext context,
    List<StudentGradeEntity> students,
    double maximumScore,
  ) async {
    final entries = <({int studentId, double grade, String? comment})>[];
    final invalidNames = <String>[];
    for (final student in students) {
      final text = controllerFor(student).text.trim();
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
    _saving = true;
    notifyListeners();
    final error = await context.read<ActivitiesProvider>().saveGrades(
      activityId,
      entries,
    );
    _saving = false;
    notifyListeners();
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Calificaciones guardadas.');
    }
  }

  /// Deletes the activity and pops back to the list.
  Future<void> delete(BuildContext context, ActivityEntity activity) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar actividad',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<ActivitiesProvider>().delete(
      activity.id,
      teachingPeriodId: activity.teachingPeriodId,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
