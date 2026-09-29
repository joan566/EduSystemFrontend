import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../grades/domain/entities/grading_entities.dart';
import '../../../grades/presentation/providers/grading_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/student_entity.dart';

/// A student's period grade in one of the teacher's classes.
class StudentClassGrade {
  const StudentClassGrade({
    required this.period,
    this.scale,
    this.grade,
    this.error,
  });

  final TeachingPeriodEntity period;
  final GradingScaleEntity? scale;

  /// Null when the class has no grades for the student (e.g. withdrawn
  /// before grading) or [error] is set.
  final StudentPeriodGrade? grade;

  /// E.g. `GRADING_CONFIGURATION_REQUIRED` when the class isn't set up.
  final AppException? error;

  bool get needsConfiguration =>
      error?.code == 'GRADING_CONFIGURATION_REQUIRED';
}

/// Loads a student's grades across the teacher's classes of every course
/// they've been enrolled in: one period-grades request per class, read
/// for this student. Owned by the detail page so the result survives a
/// layout switch; loaded the first time the "Notas" tab is shown.
class StudentGradesController extends ChangeNotifier {
  StudentGradesController({required this.teaching, required this.grading});

  final TeachingProvider teaching;
  final GradingProvider grading;

  bool _loading = false;
  bool get loading => _loading;

  List<StudentClassGrade>? _grades;

  /// Null until loaded; newest classes first.
  List<StudentClassGrade>? get grades => _grades;

  int? _loadedFor;
  bool _disposed = false;

  Future<void> ensureLoaded(StudentDetailEntity detail) async {
    if (_loadedFor == detail.student.id || _loading) return;
    await reload(detail);
  }

  Future<void> reload(StudentDetailEntity detail) async {
    _loading = true;
    _notify();
    await teaching.ensureAllPeriodsLoaded();
    final groups = {for (final e in detail.enrollments) e.groupId};
    final classes =
        teaching.allPeriods.where((p) => groups.contains(p.groupId)).toList()
          ..sort((a, b) {
            final byStart = b.startDate.compareTo(a.startDate);
            return byStart != 0
                ? byStart
                : a.subjectName.compareTo(b.subjectName);
          });

    final results = await Future.wait([
      for (final period in classes) _gradeIn(period, detail.student.id),
    ]);
    if (_disposed) return;
    _grades = results;
    _loadedFor = detail.student.id;
    _loading = false;
    _notify();
  }

  Future<StudentClassGrade> _gradeIn(
    TeachingPeriodEntity period,
    int studentId,
  ) async {
    try {
      final grades = await grading.fetchPeriodGrades(period.id);
      return StudentClassGrade(
        period: period,
        scale: grades.scale,
        grade: grades.students
            .where((s) => s.studentId == studentId)
            .firstOrNull,
      );
    } on AppException catch (e) {
      return StudentClassGrade(period: period, error: e);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The enrollment to show as the student's course: the active one, else
/// the most recent.
StudentEnrollmentEntity? currentEnrollmentOf(StudentDetailEntity detail) {
  final enrollments = [...detail.enrollments]
    ..sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      final byYear = b.academicYear.compareTo(a.academicYear);
      return byYear != 0 ? byYear : b.enrolledAt.compareTo(a.enrolledAt);
    });
  return enrollments.firstOrNull;
}
