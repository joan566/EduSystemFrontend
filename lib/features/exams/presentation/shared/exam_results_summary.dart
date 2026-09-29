import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_entity.dart';

/// One bin of the grade distribution: grades in [from, to) (the last bin
/// also includes [to]).
class GradeBin {
  const GradeBin({required this.from, required this.to, required this.count});

  final double from;
  final double to;
  final int count;
}

/// Figures derived from an exam's loaded submissions.
class ExamResultsSummary {
  ExamResultsSummary._({
    required this.sheets,
    required this.graded,
    required this.processed,
    required this.reviewRequired,
    required this.failed,
    required this.average,
    required this.lowest,
    required this.highest,
    required this.bins,
  });

  factory ExamResultsSummary.from(
    List<SubmissionSummaryEntity> items,
    ExamSummaryEntity exam, {
    int binCount = 5,
  }) {
    final grades = [
      for (final s in items)
        if (s.finalGrade != null) s.finalGrade!,
    ];
    int count(SubmissionStatus status) =>
        items.where((s) => s.status == status).length;

    final max = exam.maximumScore;
    final bins = <GradeBin>[];
    if (max != null && max > 0) {
      final width = max / binCount;
      for (var i = 0; i < binCount; i++) {
        final from = width * i;
        final to = i == binCount - 1 ? max : width * (i + 1);
        bins.add(
          GradeBin(
            from: from,
            to: to,
            count: grades
                .where(
                  (g) => i == binCount - 1
                      ? g >= from && g <= to
                      : g >= from && g < to,
                )
                .length,
          ),
        );
      }
    }

    return ExamResultsSummary._(
      sheets: items.length,
      graded: grades.length,
      processed: count(SubmissionStatus.processed),
      reviewRequired: count(SubmissionStatus.reviewRequired),
      failed: count(SubmissionStatus.failed),
      average: grades.isEmpty
          ? null
          : grades.reduce((a, b) => a + b) / grades.length,
      lowest: grades.isEmpty ? null : grades.reduce((a, b) => a < b ? a : b),
      highest: grades.isEmpty ? null : grades.reduce((a, b) => a > b ? a : b),
      bins: bins,
    );
  }

  /// Submissions loaded (one per student sheet).
  final int sheets;

  /// Sheets with a final grade.
  final int graded;
  final int processed;
  final int reviewRequired;
  final int failed;
  final double? average;
  final double? lowest;
  final double? highest;

  /// Empty when the exam has no maximum score to bin against.
  final List<GradeBin> bins;
}
