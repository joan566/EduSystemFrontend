import 'grading_entities.dart';

/// How an evaluation gets each student's result.
enum EvaluationType { exam, activity, attendance }

EvaluationType evaluationTypeFromJson(String value) => switch (value) {
  'EXAM' => EvaluationType.exam,
  'ACTIVITY' => EvaluationType.activity,
  _ => EvaluationType.attendance,
};

class GradebookStudent {
  const GradebookStudent({
    required this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
  });

  final int id;
  final String studentCode;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}'
              '${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
}

/// One evaluation of a class with a student's result in it.
class GradebookEntry {
  const GradebookEntry({
    required this.evaluationId,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.maximumScore,
    required this.excluded,
    required this.hasRubric,
    required this.hasAttachment,
    this.description,
    this.activityType,
    this.evaluationDate,
    this.earned,
    this.weight,
    this.contribution,
    this.comment,
    this.gradedAt,
    this.activityId,
    this.examId,
    this.submissionId,
  });

  final int evaluationId;
  final String name;
  final String? description;
  final EvaluationType type;
  final String? activityType;
  final int categoryId;
  final String categoryName;
  final DateTime? evaluationDate;
  final double maximumScore;

  /// Points earned out of [maximumScore]; null when not graded yet.
  final double? earned;

  /// Doesn't count towards the grade (excused or unrecorded attendance).
  final bool excluded;

  /// Effective weight in the final grade (%): the category's weight split
  /// by each evaluation's maximum score. Null without a configuration.
  final double? weight;

  /// Points (out of 100) this evaluation adds to the final grade; null
  /// without a complete configuration or when [excluded].
  final double? contribution;
  final String? comment;
  final DateTime? gradedAt;
  final int? activityId;
  final int? examId;
  final int? submissionId;
  final bool hasRubric;
  final bool hasAttachment;

  double? get fraction => earned == null ? null : earned! / maximumScore;
}

class StudentObservationEntity {
  const StudentObservationEntity({required this.text, this.updatedAt});

  final String text;
  final DateTime? updatedAt;
}

/// A student's grades in one class, evaluation by evaluation.
class StudentGradeReport {
  const StudentGradeReport({
    required this.teachingPeriodId,
    required this.student,
    required this.totalWeight,
    required this.configurationComplete,
    required this.categories,
    required this.evaluations,
    this.scale,
    this.passingGrade,
    this.periodGrade,
    this.score,
    this.passing,
    this.observation,
  });

  final int teachingPeriodId;
  final GradebookStudent student;

  /// Null without a grading configuration.
  final GradingScaleEntity? scale;
  final double? passingGrade;
  final double totalWeight;
  final bool configurationComplete;
  final double? periodGrade;

  /// The period grade in points out of 100.
  final double? score;
  final bool? passing;
  final List<CategoryGrade> categories;
  final List<GradebookEntry> evaluations;
  final StudentObservationEntity? observation;

  StudentGradeReport withObservation(StudentObservationEntity? value) =>
      StudentGradeReport(
        teachingPeriodId: teachingPeriodId,
        student: student,
        totalWeight: totalWeight,
        configurationComplete: configurationComplete,
        categories: categories,
        evaluations: evaluations,
        scale: scale,
        passingGrade: passingGrade,
        periodGrade: periodGrade,
        score: score,
        passing: passing,
        observation: value,
      );
}

class RubricCriterionEntity {
  const RubricCriterionEntity({
    required this.id,
    required this.name,
    required this.weight,
    required this.position,
    this.score,
  });

  final int id;
  final String name;

  /// Share of the evaluation's grade (%); criteria add up to 100.
  final double weight;
  final int position;

  /// The student's score out of the evaluation's maximum; null if not
  /// graded with the rubric yet.
  final double? score;
}

class GradeAttachmentEntity {
  const GradeAttachmentEntity({
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.updatedAt,
  });

  final String fileName;
  final String contentType;
  final int sizeBytes;
  final DateTime? updatedAt;
}

/// A student's grade in one evaluation, with its rubric and attachment.
class GradeDetailEntity {
  const GradeDetailEntity({
    required this.teachingPeriodId,
    required this.student,
    required this.evaluation,
    required this.rubric,
    this.scale,
    this.attachment,
  });

  final int teachingPeriodId;
  final GradebookStudent student;
  final GradingScaleEntity? scale;
  final GradebookEntry evaluation;
  final List<RubricCriterionEntity> rubric;
  final GradeAttachmentEntity? attachment;
}

/// An evaluation of a class, for listing a category's evaluations.
class EvaluationSummaryEntity {
  const EvaluationSummaryEntity({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.maximumScore,
    this.evaluationDate,
  });

  final int id;
  final int categoryId;
  final String name;
  final double maximumScore;
  final DateTime? evaluationDate;
}

/// A rubric criterion being defined (no id = new).
class RubricCriterionInput {
  const RubricCriterionInput({
    this.id,
    required this.name,
    required this.weight,
  });

  final int? id;
  final String name;
  final double weight;
}
