/// Grading progress and counts of one class (`GET /teaching-periods/{id}/summary`).
class TeachingPeriodSummaryEntity {
  const TeachingPeriodSummaryEntity({
    required this.teachingPeriodId,
    required this.studentCount,
    required this.activityCount,
    required this.examCount,
    required this.expectedGrades,
    required this.registeredGrades,
    required this.progressPercent,
  });

  final int teachingPeriodId;
  final int studentCount;
  final int activityCount;
  final int examCount;

  /// Active students × evaluations (activities + exams).
  final int expectedGrades;

  /// Grades already recorded for those students and evaluations.
  final int registeredGrades;

  /// Rounded by the server; 0 when nothing is expected yet.
  final int progressPercent;
}
