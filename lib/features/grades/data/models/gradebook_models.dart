import '../../../../core/utils/formatters.dart';
import '../../domain/entities/gradebook_entities.dart';
import 'grading_models.dart';

DateTime? _date(Object? value) =>
    value == null ? null : Formatters.parseApiDateTime(value as String);

double? _double(Object? value) => (value as num?)?.toDouble();

class GradebookModels {
  GradebookModels._();

  static GradebookStudent student(Map<String, dynamic> json) =>
      GradebookStudent(
        id: json['id'] as int,
        studentCode: json['studentCode'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
      );

  static GradebookEntry entry(Map<String, dynamic> json) => GradebookEntry(
    evaluationId: json['evaluationId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    type: evaluationTypeFromJson(json['type'] as String),
    activityType: json['activityType'] as String?,
    categoryId: json['categoryId'] as int,
    categoryName: json['categoryName'] as String,
    evaluationDate: _date(json['evaluationDate']),
    maximumScore: (json['maximumScore'] as num).toDouble(),
    earned: _double(json['earned']),
    excluded: json['excluded'] as bool,
    weight: _double(json['weight']),
    contribution: _double(json['contribution']),
    comment: json['comment'] as String?,
    gradedAt: _date(json['gradedAt']),
    activityId: json['activityId'] as int?,
    examId: json['examId'] as int?,
    submissionId: json['submissionId'] as int?,
    hasRubric: json['hasRubric'] as bool,
    hasAttachment: json['hasAttachment'] as bool,
  );

  static StudentObservationEntity? observation(Object? json) {
    if (json == null) return null;
    final map = json as Map<String, dynamic>;
    return StudentObservationEntity(
      text: map['text'] as String,
      updatedAt: _date(map['updatedAt']),
    );
  }

  static StudentGradeReport report(Map<String, dynamic> json) =>
      StudentGradeReport(
        teachingPeriodId: json['teachingPeriodId'] as int,
        student: student(json['student'] as Map<String, dynamic>),
        scale: json['scale'] == null
            ? null
            : GradingScaleModel.fromJson(json['scale'] as Map<String, dynamic>),
        passingGrade: _double(json['passingGrade']),
        totalWeight: (json['totalWeight'] as num).toDouble(),
        configurationComplete: json['configurationComplete'] as bool,
        periodGrade: _double(json['periodGrade']),
        score: _double(json['score']),
        passing: json['passing'] as bool?,
        categories: [
          for (final c in json['categories'] as List<dynamic>)
            PeriodGradesModel.categoryFromJson(c as Map<String, dynamic>),
        ],
        evaluations: [
          for (final e in json['evaluations'] as List<dynamic>)
            entry(e as Map<String, dynamic>),
        ],
        observation: observation(json['observation']),
      );

  static RubricCriterionEntity criterion(Map<String, dynamic> json) =>
      RubricCriterionEntity(
        id: json['id'] as int,
        name: json['name'] as String,
        weight: (json['weight'] as num).toDouble(),
        position: json['position'] as int,
        score: _double(json['score']),
      );

  static GradeAttachmentEntity? attachment(Object? json) {
    if (json == null) return null;
    final map = json as Map<String, dynamic>;
    return GradeAttachmentEntity(
      fileName: map['fileName'] as String,
      contentType: map['contentType'] as String,
      sizeBytes: map['sizeBytes'] as int,
      updatedAt: _date(map['updatedAt']),
    );
  }

  static GradeDetailEntity detail(Map<String, dynamic> json) =>
      GradeDetailEntity(
        teachingPeriodId: json['teachingPeriodId'] as int,
        student: student(json['student'] as Map<String, dynamic>),
        scale: json['scale'] == null
            ? null
            : GradingScaleModel.fromJson(json['scale'] as Map<String, dynamic>),
        evaluation: entry(json['evaluation'] as Map<String, dynamic>),
        rubric: [
          for (final c in json['rubric'] as List<dynamic>)
            criterion(c as Map<String, dynamic>),
        ],
        attachment: attachment(json['attachment']),
      );

  static EvaluationSummaryEntity evaluation(Map<String, dynamic> json) =>
      EvaluationSummaryEntity(
        id: json['id'] as int,
        categoryId: json['categoryId'] as int,
        name: json['name'] as String,
        maximumScore: (json['maximumScore'] as num).toDouble(),
        evaluationDate: _date(json['evaluationDate']),
      );
}
