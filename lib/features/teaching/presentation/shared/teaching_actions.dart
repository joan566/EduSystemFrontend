import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../providers/teaching_provider.dart';
import 'teaching_forms.dart';

/// Teaching mutations with user feedback, shared by the mobile and desktop
/// views. Each view presents the forms its own way.
class TeachingActions {
  TeachingActions._();

  /// Options for an [AssignmentForm] — the whole subject and course
  /// catalogs, never a screen's filtered page — or null (after telling the
  /// user why) when they can't be offered.
  static Future<({List<SubjectEntity> subjects, List<CourseEntity> courses})?>
  assignmentFormInputs(BuildContext context) async {
    final subjects = context.read<SubjectsProvider>();
    final courses = context.read<CoursesProvider>();
    // Usually already in memory; read now if this screen didn't need them.
    await Future.wait([subjects.ensure(), courses.ensure()]);
    if (!context.mounted) return null;
    final failure = subjects.state.error ?? courses.state.error;
    if (failure != null) {
      context.showApiError(failure);
      return null;
    }
    if (subjects.all.isEmpty || courses.all.isEmpty) {
      context.showWarning('Necesitas al menos una materia y un curso creados.');
      return null;
    }
    return (subjects: subjects.all, courses: courses.all);
  }

  /// Options for a [TeachingPeriodForm] (every active assignment and every
  /// academic period), or null (after telling the user why) when there
  /// isn't an active assignment and an academic period yet.
  static Future<
    ({
      List<TeachingAssignmentEntity> assignments,
      List<AcademicPeriodEntity> periods,
    })?
  >
  periodFormInputs(BuildContext context) async {
    final academicPeriods = context.read<AcademicPeriodsProvider>();
    final teaching = context.read<TeachingProvider>();
    await Future.wait([academicPeriods.ensure(), teaching.ensureAssignments()]);
    if (!context.mounted) return null;
    final failure =
        academicPeriods.state.error ?? teaching.assignmentsState.error;
    if (failure != null) {
      context.showApiError(failure);
      return null;
    }
    final periods = academicPeriods.all;
    final assignments = teaching.allAssignments.where((a) => a.active).toList();
    if (assignments.isEmpty || periods.isEmpty) {
      context.showWarning(
        'Necesitas una asignación activa y un periodo académico creados.',
      );
      return null;
    }
    return (assignments: assignments, periods: periods);
  }

  static Future<void> createAssignment(
    BuildContext context,
    AssignmentFormResult data,
  ) async {
    final error = await context.read<TeachingProvider>().createAssignment(
      groupId: data.groupId,
      subjectId: data.subjectId,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Asignación creada.');
    }
  }

  static Future<void> createPeriod(
    BuildContext context,
    TeachingPeriodFormResult data,
  ) async {
    final error = await context.read<TeachingProvider>().createPeriod(
      teachingAssignmentId: data.teachingAssignmentId,
      academicPeriodId: data.academicPeriodId,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Clase creada.');
    }
  }

  /// Creates [assignment]'s class in [academicPeriod] directly — both are
  /// already known, so no form is needed.
  static Future<void> createClassFor(
    BuildContext context, {
    required TeachingAssignmentEntity assignment,
    required AcademicPeriodEntity academicPeriod,
  }) async {
    final error = await context.read<TeachingProvider>().createPeriod(
      teachingAssignmentId: assignment.id,
      academicPeriodId: academicPeriod.id,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        'Clase de ${assignment.subjectName} creada en ${academicPeriod.name}.',
      );
    }
  }

  static Future<void> setAssignmentActive(
    BuildContext context,
    TeachingAssignmentEntity item,
    bool active,
  ) async {
    final error = await context.read<TeachingProvider>().setAssignmentActive(
      item.id,
      active,
    );
    if (context.mounted && error != null) context.showApiError(error);
  }

  static Future<void> deleteAssignment(
    BuildContext context,
    TeachingAssignmentEntity item,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar asignación',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<TeachingProvider>().deleteAssignment(
      item.id,
    );
    if (context.mounted && error != null) context.showApiError(error);
  }

  /// Returns whether the class was deleted.
  static Future<bool> deletePeriod(
    BuildContext context,
    TeachingPeriodEntity item,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar clase',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return false;
    final error = await context.read<TeachingProvider>().deletePeriod(item.id);
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess('Clase eliminada.');
    return true;
  }
}

/// Filters of the assignments tab. Lives in the page entry point so they
/// survive a mobile <-> desktop switch.
class AssignmentFilters {
  const AssignmentFilters({this.subjectId, this.active});

  final int? subjectId;
  final bool? active;
}
