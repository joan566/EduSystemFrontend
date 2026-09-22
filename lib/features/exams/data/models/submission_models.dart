import '../../../../core/utils/formatters.dart';
import '../../domain/entities/submission_entity.dart';

class SubmissionAnswerModel {
  static SubmissionAnswer fromJson(Map<String, dynamic> json) =>
      SubmissionAnswer(
        questionNumber: json['questionNumber'] as int,
        statement: json['statement'] as String? ?? '',
        selectedOption: json['selectedOption'] as String?,
        correctOption: json['correctOption'] as String,
        correct: json['correct'] as bool?,
        detectionStatus: detectionStatusFromJson(
          json['detectionStatus'] as String,
        ),
        detectionConfidence: (json['detectionConfidence'] as num?)?.toDouble(),
        points: (json['points'] as num?)?.toDouble(),
        needsReview: json['needsReview'] as bool? ?? false,
      );
}

class SubmissionSummaryModel {
  static SubmissionSummaryEntity fromJson(Map<String, dynamic> json) =>
      SubmissionSummaryEntity(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        studentCode: json['studentCode'] as String,
        studentName: json['studentName'] as String,
        status: submissionStatusFromJson(json['status'] as String),
        score: (json['score'] as num?)?.toDouble(),
        finalGrade: (json['finalGrade'] as num?)?.toDouble(),
        statusDetail: json['statusDetail'] as String?,
        submittedAt: json['submittedAt'] == null
            ? null
            : Formatters.parseApiDateTime(json['submittedAt'] as String),
        processedAt: json['processedAt'] == null
            ? null
            : Formatters.parseApiDateTime(json['processedAt'] as String),
      );
}

class SubmissionModel {
  static SubmissionEntity fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'] as Map<String, dynamic>;
    return SubmissionEntity(
      id: json['id'] as int,
      examId: json['examId'] as int,
      examName: json['examName'] as String? ?? '',
      student: SubmissionStudent(
        id: studentJson['id'] as int,
        studentCode: studentJson['studentCode'] as String,
        name: studentJson['name'] as String,
      ),
      status: submissionStatusFromJson(json['status'] as String),
      statusDetail: json['statusDetail'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      maximumScore: (json['maximumScore'] as num?)?.toDouble(),
      finalGrade: (json['finalGrade'] as num?)?.toDouble(),
      scaleMinimum: (json['scaleMinimum'] as num?)?.toDouble(),
      scaleMaximum: (json['scaleMaximum'] as num?)?.toDouble(),
      submittedAt: json['submittedAt'] == null
          ? null
          : Formatters.parseApiDateTime(json['submittedAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : Formatters.parseApiDateTime(json['processedAt'] as String),
      hasImage: json['hasImage'] as bool? ?? false,
      answers: (json['answers'] as List<dynamic>? ?? const [])
          .map((e) => SubmissionAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
