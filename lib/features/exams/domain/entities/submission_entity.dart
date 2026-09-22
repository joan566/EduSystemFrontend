enum SubmissionStatus { pending, processing, processed, reviewRequired, failed }

SubmissionStatus submissionStatusFromJson(String value) => switch (value) {
  'PENDING' => SubmissionStatus.pending,
  'PROCESSING' => SubmissionStatus.processing,
  'PROCESSED' => SubmissionStatus.processed,
  'REVIEW_REQUIRED' => SubmissionStatus.reviewRequired,
  'FAILED' => SubmissionStatus.failed,
  _ => SubmissionStatus.failed,
};

enum DetectionStatus { marked, empty, multipleMark, reviewRequired, manual }

DetectionStatus detectionStatusFromJson(String value) => switch (value) {
  'MARKED' => DetectionStatus.marked,
  'EMPTY' => DetectionStatus.empty,
  'MULTIPLE_MARK' => DetectionStatus.multipleMark,
  'REVIEW_REQUIRED' => DetectionStatus.reviewRequired,
  'MANUAL' => DetectionStatus.manual,
  _ => DetectionStatus.empty,
};

class SubmissionStudent {
  const SubmissionStudent({
    required this.id,
    required this.studentCode,
    required this.name,
  });

  final int id;
  final String studentCode;
  final String name;
}

class SubmissionAnswer {
  const SubmissionAnswer({
    required this.questionNumber,
    required this.statement,
    this.selectedOption,
    required this.correctOption,
    this.correct,
    required this.detectionStatus,
    this.detectionConfidence,
    this.points,
    required this.needsReview,
  });

  final int questionNumber;
  final String statement;
  final String? selectedOption;
  final String correctOption;
  final bool? correct;
  final DetectionStatus detectionStatus;
  final double? detectionConfidence;
  final double? points;
  final bool needsReview;
}

/// Row shape from `GET /exams/{id}/submissions` (§51 listing).
class SubmissionSummaryEntity {
  const SubmissionSummaryEntity({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.status,
    this.score,
    this.finalGrade,
    this.statusDetail,
    this.submittedAt,
    this.processedAt,
  });

  final int id;
  final int studentId;
  final String studentCode;
  final String studentName;
  final SubmissionStatus status;
  final double? score;
  final double? finalGrade;
  final String? statusDetail;
  final DateTime? submittedAt;
  final DateTime? processedAt;
}

/// Full detail — `GET .../submissions/{id}` (§46-48: review & correction).
class SubmissionEntity {
  const SubmissionEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.student,
    required this.status,
    this.statusDetail,
    this.score,
    this.maximumScore,
    this.finalGrade,
    this.scaleMinimum,
    this.scaleMaximum,
    this.submittedAt,
    this.processedAt,
    required this.hasImage,
    required this.answers,
  });

  final int id;
  final int examId;
  final String examName;
  final SubmissionStudent student;
  final SubmissionStatus status;
  final String? statusDetail;
  final double? score;
  final double? maximumScore;
  final double? finalGrade;
  final double? scaleMinimum;
  final double? scaleMaximum;
  final DateTime? submittedAt;
  final DateTime? processedAt;
  final bool hasImage;
  final List<SubmissionAnswer> answers;

  int get correctCount => answers.where((a) => a.correct == true).length;
  int get incorrectCount => answers
      .where((a) => a.correct == false && a.selectedOption != null)
      .length;
  int get unansweredCount =>
      answers.where((a) => a.selectedOption == null).length;
}
