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

/// A student's grades across the teacher's classes of every course they've
/// been enrolled in, read from each class's period grades.
///
/// A class's period grades are one response for all its students, cached
/// per class by [GradingProvider]: looking at another student of the same
/// classes (the detail, the desktop preview walking the table) reuses them
/// instead of asking once per student and class. Owned by the detail page
/// so it survives a layout switch; loaded the first time "Notas" is shown.
class StudentGradesController extends ChangeNotifier {
  StudentGradesController({required this.teaching, required this.grading}) {
    teaching.addListener(_notify);
    grading.addListener(_notify);
  }

  final TeachingProvider teaching;
  final GradingProvider grading;

  StudentDetailEntity? _detail;
  bool _classesKnown = false;
  bool _disposed = false;

  /// The teacher's classes in the student's courses, newest first.
  List<TeachingPeriodEntity> _classes() {
    final detail = _detail;
    if (detail == null) return const [];
    final groups = {for (final e in detail.enrollments) e.groupId};
    return teaching.allPeriods.where((p) => groups.contains(p.groupId)).toList()
      ..sort((a, b) {
        final byStart = b.startDate.compareTo(a.startDate);
        return byStart != 0 ? byStart : a.subjectName.compareTo(b.subjectName);
      });
  }

  /// Null until every class's grades are known; newest classes first.
  List<StudentClassGrade>? get grades {
    final detail = _detail;
    if (detail == null || !_classesKnown) return null;
    final result = <StudentClassGrade>[];
    for (final period in _classes()) {
      final state = grading.periodGrades(period.id);
      final data = state.data;
      if (data != null) {
        result.add(
          StudentClassGrade(
            period: period,
            scale: data.scale,
            grade: data.students
                .where((s) => s.studentId == detail.student.id)
                .firstOrNull,
          ),
        );
      } else if (state.error != null) {
        result.add(StudentClassGrade(period: period, error: state.error));
      } else {
        return null; // still loading
      }
    }
    return result;
  }

  bool get loading => _detail != null && grades == null;

  /// Reads what isn't cached yet (at most one request per class, shared by
  /// every student of it).
  Future<void> ensureLoaded(StudentDetailEntity detail) => _load(detail);

  /// Re-reads the period grades of the student's classes.
  Future<void> reload(StudentDetailEntity detail) =>
      _load(detail, refresh: true);

  Future<void> _load(StudentDetailEntity detail, {bool refresh = false}) async {
    _detail = detail;
    _notify();
    await teaching.ensureAllPeriodsLoaded();
    if (_disposed) return;
    _classesKnown = true;
    await Future.wait([
      for (final period in _classes())
        refresh
            ? grading.refreshPeriodGrades(period.id)
            : grading.ensurePeriodGrades(period.id),
    ]);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    teaching.removeListener(_notify);
    grading.removeListener(_notify);
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
