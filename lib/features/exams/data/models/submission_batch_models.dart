import '../../../../core/utils/formatters.dart';
import '../../domain/entities/submission_batch_entity.dart';
import 'submission_models.dart';

DateTime? _dateTime(Object? value) =>
    value == null ? null : Formatters.parseApiDateTime(value as String);

double? _double(Object? value) => (value as num?)?.toDouble();

class SubmissionBatchSummaryModel {
  static SubmissionBatchSummaryEntity fromJson(Map<String, dynamic> json) =>
      SubmissionBatchSummaryEntity(
        id: json['id'] as int,
        examId: json['examId'] as int,
        fileName: json['fileName'] as String? ?? '',
        status: submissionBatchStatusFromJson(json['status'] as String),
        statusDetail: json['statusDetail'] as String?,
        totalPages: json['totalPages'] as int? ?? 0,
        processedPages: json['processedPages'] as int? ?? 0,
        progressPercent: json['progressPercent'] as int? ?? 0,
        replaceExisting: json['replaceExisting'] as bool? ?? false,
        createdAt: _dateTime(json['createdAt']),
        startedAt: _dateTime(json['startedAt']),
        completedAt: _dateTime(json['completedAt']),
        filePurgedAt: _dateTime(json['filePurgedAt']),
      );
}

class SubmissionBatchModel {
  static SubmissionBatchEntity fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>? ?? const {};
    return SubmissionBatchEntity(
      batch: SubmissionBatchSummaryModel.fromJson(
        json['batch'] as Map<String, dynamic>,
      ),
      results: BatchResults(
        processed: results['processed'] as int? ?? 0,
        reviewRequired: results['reviewRequired'] as int? ?? 0,
        failed: results['failed'] as int? ?? 0,
        rejected: results['rejected'] as int? ?? 0,
        skipped: results['skipped'] as int? ?? 0,
        graded: results['graded'] as int? ?? 0,
        averageScore: _double(results['averageScore']),
        averageFinalGrade: _double(results['averageFinalGrade']),
        highestFinalGrade: _double(results['highestFinalGrade']),
        lowestFinalGrade: _double(results['lowestFinalGrade']),
      ),
      pages: (json['pages'] as List<dynamic>? ?? const []).map((e) {
        final page = e as Map<String, dynamic>;
        final submission = page['submission'] as Map<String, dynamic>?;
        return BatchPage(
          page: page['page'] as int,
          outcome: batchPageOutcomeFromJson(page['outcome'] as String),
          errorCode: page['errorCode'] as String?,
          message: page['message'] as String?,
          submission: submission == null
              ? null
              : SubmissionSummaryModel.fromJson(submission),
        );
      }).toList(),
    );
  }
}
