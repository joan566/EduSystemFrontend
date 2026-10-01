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

  /// Options for an [AddClassesForm] — the whole course, subject and
  /// period catalogs — or null (after telling the user why) when they
  /// can't be offered.
  static Future<
    ({
      List<CourseEntity> courses,
      List<SubjectEntity> subjects,
      List<AcademicPeriodEntity> academicPeriods,
      List<TeachingAssignmentEntity> assignments,
    })?
  >
  addClassesFormInputs(BuildContext context) async {
    final subjects = context.read<SubjectsProvider>();
    final courses = context.read<CoursesProvider>();
    final academicPeriods = context.read<AcademicPeriodsProvider>();
    final teaching = context.read<TeachingProvider>();
    // Usually already in memory; read now if this screen didn't need them.
    await Future.wait([
      subjects.ensure(),
      courses.ensure(),
      academicPeriods.ensure(),
      teaching.ensureAssignments(),
      teaching.ensureAllPeriodsLoaded(),
    ]);
    if (!context.mounted) return null;
    final failure =
        subjects.state.error ??
        courses.state.error ??
        academicPeriods.state.error ??
        teaching.assignmentsState.error;
    if (failure != null) {
      context.showApiError(failure);
      return null;
    }
    if (subjects.all.isEmpty || courses.all.isEmpty) {
      context.showWarning('Necesitas al menos una materia y un curso creados.');
      return null;
    }
    return (
      courses: courses.all,
      subjects: subjects.all,
      academicPeriods: academicPeriods.all,
      assignments: teaching.allAssignments,
    );
  }

  /// Returns whether the classes were added (the form closes on true).
  static Future<bool> addClasses(
    BuildContext context,
    AddClassesResult data,
  ) async {
    final (:created, :error) = await context
        .read<TeachingProvider>()
        .addClasses(
          groupId: data.groupId,
          subjectIds: data.subjectIds,
          academicPeriodId: data.academicPeriodId,
        );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    if (created == 0) {
      context.showInfo('Ya dictas esas materias en ese curso y periodo.');
    } else {
      context.showSuccess(
        created == 1 ? 'Clase agregada.' : '$created clases agregadas.',
      );
    }
    return true;
  }

  /// Creates [assignment]'s class in [academicPeriod] directly — both are
  /// already known, so no form is needed.
  static Future<void> createClassFor(
    BuildContext context, {
    required TeachingAssignmentEntity assignment,
    required AcademicPeriodEntity academicPeriod,
  }) async {
    final teaching = context.read<TeachingProvider>();
    if (teaching.isCreatingClassFor(assignment.id)) return;
    final error = await teaching.createPeriod(
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

  /// Stops teaching [item]'s subject in its course (the assignment and
  /// its classes).
  static Future<void> deleteAssignment(
    BuildContext context,
    TeachingAssignmentEntity item,
  ) async {
    await showAppConfirmDialog(
      context,
      title: 'Quitar ${item.subjectName} de ${item.courseLabel}',
      message:
          'Dejarás de dictar esta materia en el curso. Esta acción no se '
          'puede deshacer.',
      confirmLabel: 'Quitar',
      onConfirm: () async {
        final error = await context.read<TeachingProvider>().deleteAssignment(
          item.id,
        );
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          context.showSuccess(
            '${item.subjectName} quitada de ${item.courseLabel}.',
          );
        }
      },
    );
  }

  /// Returns whether the class was deleted.
  static Future<bool> deletePeriod(
    BuildContext context,
    TeachingPeriodEntity item,
  ) async {
    var deleted = false;
    await showAppConfirmDialog(
      context,
      title: 'Eliminar clase de ${item.academicPeriodName}',
      message:
          'Se elimina la clase de ${item.title} en '
          '${item.academicPeriodName}. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      onConfirm: () async {
        final error = await context.read<TeachingProvider>().deletePeriod(
          item.id,
        );
        deleted = error == null;
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          context.showSuccess('Clase eliminada.');
        }
      },
    );
    return deleted;
  }
}

/// Filters of the Clases screen (subject and active state). Live in the
/// page entry point so they survive a mobile <-> desktop switch.
class AssignmentFilters {
  const AssignmentFilters({this.subjectId, this.active});

  final int? subjectId;
  final bool? active;
}
