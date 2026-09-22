import '../../../../core/utils/formatters.dart';
import '../../domain/entities/activity_entity.dart';

class ActivityModel {
  static ActivityEntity fromJson(Map<String, dynamic> json) => ActivityEntity(
    id: json['id'] as int,
    evaluationId: json['evaluationId'] as int,
    teachingPeriodId: json['teachingPeriodId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    evaluationDate: json['evaluationDate'] == null
        ? null
        : Formatters.parseApiDateTime(json['evaluationDate'] as String),
    maximumScore: (json['maximumScore'] as num).toDouble(),
    activityType: json['activityType'] as String?,
  );

  static Map<String, dynamic> toCreateRequest({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    required double maximumScore,
    String? activityType,
  }) => {
    'teachingPeriodId': teachingPeriodId,
    'name': name,
    'description': description,
    if (evaluationDate != null) 'evaluationDate': Formatters.toApiDateTime(evaluationDate),
    'maximumScore': maximumScore,
    'activityType': activityType,
  };

  static Map<String, dynamic> toUpdateRequest({
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    String? activityType,
  }) => {
    'name': name,
    'description': description,
    if (evaluationDate != null) 'evaluationDate': Formatters.toApiDateTime(evaluationDate),
    if (maximumScore != null) 'maximumScore': maximumScore,
    'activityType': activityType,
  };
}

class StudentGradeModel {
  static StudentGradeEntity fromJson(Map<String, dynamic> json) => StudentGradeEntity(
    studentId: json['studentId'] as int,
    studentCode: json['studentCode'] as String,
    studentName: json['studentName'] as String,
    grade: (json['grade'] as num?)?.toDouble(),
    comment: json['comment'] as String?,
    gradedAt: json['gradedAt'] == null
        ? null
        : Formatters.parseApiDateTime(json['gradedAt'] as String),
  );
}
