import '../../../../core/utils/course_naming.dart';

/// A teaching assignment scoped to a specific academic period — the
/// central id (`teachingPeriodId`) that exams, activities, attendance and
/// grading all hang off (§4).
class TeachingPeriodEntity {
  const TeachingPeriodEntity({
    required this.id,
    required this.teachingAssignmentId,
    required this.groupId,
    required this.groupName,
    required this.gradeName,
    required this.academicYear,
    required this.subjectId,
    required this.subjectName,
    required this.academicPeriodId,
    required this.academicPeriodName,
    required this.startDate,
    required this.endDate,
    this.studentCount = 0,
  });

  final int id;
  final int teachingAssignmentId;
  final int groupId;
  final String groupName;
  final String gradeName;
  final int academicYear;
  final int subjectId;
  final String subjectName;
  final int academicPeriodId;
  final String academicPeriodName;
  final DateTime startDate;
  final DateTime endDate;

  /// Active students in the group.
  final int studentCount;

  /// "6° A".
  String get courseLabel => courseName(gradeName, groupName);

  /// "Matemáticas · 6° A".
  String get title => '$subjectName · $courseLabel';

  /// [title] with its academic period, where classes of several periods
  /// are listed together.
  String get displayName => '$title ($academicPeriodName)';
}
