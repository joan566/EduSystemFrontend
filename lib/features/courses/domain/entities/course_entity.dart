import '../../../../core/utils/course_naming.dart';

/// A "grupo" (course section), e.g. "10-A" for academic year 2026,
/// belonging to a [gradeId] level.
class CourseEntity {
  const CourseEntity({
    required this.id,
    required this.gradeId,
    required this.gradeName,
    required this.name,
    required this.academicYear,
  });

  final int id;
  final int gradeId;
  final String gradeName;
  final String name;
  final int academicYear;

  String get displayName => courseName(gradeName, name);
}
