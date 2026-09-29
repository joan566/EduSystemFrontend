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

  /// Options for an [AssignmentForm], or null (after warning) when there
  /// isn't at least one subject and one course yet.
  static ({List<SubjectEntity> subjects, List<CourseEntity> courses})?
  assignmentFormInputs(BuildContext context) {
    final subjects = context.read<SubjectsProvider>().state.items;
    final courses = context.read<CoursesProvider>().state.items;
    if (subjects.isEmpty || courses.isEmpty) {
      context.showWarning('Necesitas al menos una materia y un curso creados.');
      return null;
    }
    return (subjects: subjects, courses: courses);
  }

  /// Options for a [TeachingPeriodForm], or null (after warning) when there
  /// isn't an active assignment and an academic period yet.
  static ({
    List<TeachingAssignmentEntity> assignments,
    List<AcademicPeriodEntity> periods,
  })?
  periodFormInputs(BuildContext context) {
    final periods = context.read<AcademicPeriodsProvider>().state.items;
    final assignments = context
        .read<TeachingProvider>()
        .assignmentsState
        .items
        .where((a) => a.active)
        .toList();
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
