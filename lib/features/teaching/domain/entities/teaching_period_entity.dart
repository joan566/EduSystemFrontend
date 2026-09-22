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

  String get displayName => '$subjectName — $gradeName $groupName ($academicPeriodName)';
  String get courseLabel => '$gradeName $groupName';
}
