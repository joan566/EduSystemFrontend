import '../../../teaching/domain/entities/teaching_period_entity.dart';

/// The Cursos screen's filters, both sent to the API. Owned by the page so
/// they survive a layout switch.
class CourseFilters {
  const CourseFilters({this.gradeId, this.academicYear});

  final int? gradeId;
  final int? academicYear;
}

/// What the teacher does in each course: their classes there, by course
/// (group) id.
Map<int, List<TeachingPeriodEntity>> classesByCourse(
  List<TeachingPeriodEntity> classes,
) {
  final result = <int, List<TeachingPeriodEntity>>{};
  for (final c in classes) {
    (result[c.groupId] ??= []).add(c);
  }
  return result;
}

/// Distinct subjects taught among [classes], sorted.
List<String> subjectsOf(List<TeachingPeriodEntity> classes) =>
    {for (final c in classes) c.subjectName}.toList()..sort();

/// Active students of the course, as reported by any of its classes.
int? studentsOf(List<TeachingPeriodEntity> classes) => classes.isEmpty
    ? null
    : classes.map((c) => c.studentCount).reduce((a, b) => a > b ? a : b);

/// Years to offer as filters: the current one and the ones around it.
List<int> filterYears() {
  final now = DateTime.now().year;
  return [now + 1, now, now - 1, now - 2];
}
