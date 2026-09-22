class ActivityEntity {
  const ActivityEntity({
    required this.id,
    required this.evaluationId,
    required this.teachingPeriodId,
    required this.name,
    this.description,
    this.evaluationDate,
    required this.maximumScore,
    this.activityType,
  });

  final int id;
  final int evaluationId;
  final int teachingPeriodId;
  final String name;
  final String? description;
  final DateTime? evaluationDate;
  final double maximumScore;
  final String? activityType;
}

class StudentGradeEntity {
  const StudentGradeEntity({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    this.grade,
    this.comment,
    this.gradedAt,
  });

  final int studentId;
  final String studentCode;
  final String studentName;
  final double? grade;
  final String? comment;
  final DateTime? gradedAt;

  StudentGradeEntity copyWith({double? grade, String? comment}) => StudentGradeEntity(
    studentId: studentId,
    studentCode: studentCode,
    studentName: studentName,
    grade: grade ?? this.grade,
    comment: comment ?? this.comment,
    gradedAt: gradedAt,
  );
}
