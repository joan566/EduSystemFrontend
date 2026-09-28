import 'submission_entity.dart';

enum SubmissionBatchStatus { queued, processing, completed, failed }

SubmissionBatchStatus submissionBatchStatusFromJson(String value) =>
    switch (value) {
      'QUEUED' => SubmissionBatchStatus.queued,
      'PROCESSING' => SubmissionBatchStatus.processing,
      'COMPLETED' => SubmissionBatchStatus.completed,
      'FAILED' => SubmissionBatchStatus.failed,
      _ => SubmissionBatchStatus.failed,
    };

enum BatchPageOutcome { processed, reviewRequired, failed, rejected, skipped }

BatchPageOutcome batchPageOutcomeFromJson(String value) => switch (value) {
  'PROCESSED' => BatchPageOutcome.processed,
  'REVIEW_REQUIRED' => BatchPageOutcome.reviewRequired,
  'FAILED' => BatchPageOutcome.failed,
  'REJECTED' => BatchPageOutcome.rejected,
  'SKIPPED' => BatchPageOutcome.skipped,
  _ => BatchPageOutcome.rejected,
};

/// A scanned-sheets PDF upload, graded in the background. Shape of the
/// `POST .../submissions/batches` response and of each history row.
class SubmissionBatchSummaryEntity {
  const SubmissionBatchSummaryEntity({
    required this.id,
    required this.examId,
    required this.fileName,
    required this.status,
    this.statusDetail,
    required this.totalPages,
    required this.processedPages,
    required this.progressPercent,
    required this.replaceExisting,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.filePurgedAt,
  });

  final int id;
  final int examId;
  final String fileName;
  final SubmissionBatchStatus status;

  /// Reason when [status] is `FAILED` (English, from the backend).
  final String? statusDetail;
  final int totalPages;
  final int processedPages;
  final int progressPercent;
  final bool replaceExisting;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? filePurgedAt;

  bool get isFinished =>
      status == SubmissionBatchStatus.completed ||
      status == SubmissionBatchStatus.failed;
}

/// Outcome counts plus grade stats over the sheets that got a grade.
/// Averages and extremes are null when [graded] is 0.
class BatchResults {
  const BatchResults({
    required this.processed,
    required this.reviewRequired,
    required this.failed,
    required this.rejected,
    required this.skipped,
    required this.graded,
    this.averageScore,
    this.averageFinalGrade,
    this.highestFinalGrade,
    this.lowestFinalGrade,
  });

  final int processed;
  final int reviewRequired;
  final int failed;
  final int rejected;
  final int skipped;
  final int graded;
  final double? averageScore;
  final double? averageFinalGrade;
  final double? highestFinalGrade;
  final double? lowestFinalGrade;
}

class BatchPage {
  const BatchPage({
    required this.page,
    required this.outcome,
    this.errorCode,
    this.message,
    this.submission,
  });

  final int page;
  final BatchPageOutcome outcome;

  /// Set on `REJECTED` pages, e.g. `QR_NOT_DETECTED`.
  final String? errorCode;
  final String? message;

  /// Null on `REJECTED` and `SKIPPED` pages.
  final SubmissionSummaryEntity? submission;
}

/// Full detail — `GET .../submissions/batches/{batchId}`. While the batch
/// runs, [pages] holds only the pages already resolved.
class SubmissionBatchEntity {
  const SubmissionBatchEntity({
    required this.batch,
    required this.results,
    required this.pages,
  });

  final SubmissionBatchSummaryEntity batch;
  final BatchResults results;
  final List<BatchPage> pages;
}
