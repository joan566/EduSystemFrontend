import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/courses_provider.dart';
import 'course_form.dart';

/// Persistence + user feedback for course mutations, shared by the mobile
/// and desktop views.
class CourseActions {
  CourseActions._();

  /// The levels a [CourseForm] can pick from, or null (after warning the
  /// user) when there are none yet — a course can't exist without a grade.
  static List<AcademicLevelEntity>? levelsForForm(BuildContext context) {
    final levels = context.read<AcademicLevelsProvider>().all;
    if (levels.isEmpty) {
      context.showWarning('Primero crea al menos un grado académico.');
      return null;
    }
    return levels;
  }

  static Future<bool> save(
    BuildContext context, {
    CourseEntity? initial,
    required CourseFormResult data,
  }) async {
    final provider = context.read<CoursesProvider>();
    final error = initial == null
        ? await provider.create(
            gradeId: data.gradeId,
            name: data.name,
            academicYear: data.academicYear,
          )
        : await provider.update(
            initial.id,
            name: data.name,
            academicYear: data.academicYear,
          );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess(
      initial == null ? 'Curso creado.' : 'Curso actualizado.',
    );
    return true;
  }

  static Future<void> delete(BuildContext context, CourseEntity course) async {
    await showAppConfirmDialog(
      context,
      title: 'Eliminar curso',
      message:
          'Esta acción no se puede deshacer. ¿Eliminar "${course.displayName}"?',
      confirmLabel: 'Eliminar',
      onConfirm: () async {
        final error = await context.read<CoursesProvider>().delete(course.id);
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          context.showSuccess('Curso eliminado.');
        }
      },
    );
  }
}
