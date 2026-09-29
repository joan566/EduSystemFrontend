import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/utils/downloads.dart';
import '../../data/repositories/gradebook_repository.dart';
import '../../domain/entities/gradebook_entities.dart';

/// A student's report in one class and the grade detail being viewed.
/// Every mutation re-reads what it changes, so the report, the detail and
/// the class's period grades never disagree with the backend.
class GradebookProvider extends ChangeNotifier {
  GradebookProvider(this._repository);

  final GradebookRepository _repository;

  DetailViewState<StudentGradeReport> _report = const DetailViewState();
  DetailViewState<StudentGradeReport> get report => _report;

  DetailViewState<GradeDetailEntity> _detail = const DetailViewState();
  DetailViewState<GradeDetailEntity> get detail => _detail;

  // Only the latest request may write each state (a quick switch between
  // students must not show the previous one's grades).
  int _reportRequest = 0;
  int _detailRequest = 0;

  Future<void> loadReport(
    int teachingPeriodId,
    int studentId, {
    bool silent = false,
  }) async {
    final request = ++_reportRequest;
    if (!silent) {
      _report = DetailViewState.loading();
      notifyListeners();
    }
    try {
      final report = await _repository.getReport(teachingPeriodId, studentId);
      if (request != _reportRequest) return;
      _report = DetailViewState.success(report);
    } on AppException catch (e) {
      if (request != _reportRequest) return;
      _report = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> loadDetail(
    int evaluationId,
    int studentId, {
    bool silent = false,
  }) async {
    final request = ++_detailRequest;
    if (!silent) {
      _detail = DetailViewState.loading();
      notifyListeners();
    }
    try {
      final detail = await _repository.getDetail(evaluationId, studentId);
      if (request != _detailRequest) return;
      _detail = DetailViewState.success(detail);
    } on AppException catch (e) {
      if (request != _detailRequest) return;
      _detail = DetailViewState.error(e);
    }
    notifyListeners();
  }

  /// Fetches a report without touching [report] (e.g. a list preview).
  /// Throws [AppException].
  Future<StudentGradeReport> fetchReport(int teachingPeriodId, int studentId) =>
      _repository.getReport(teachingPeriodId, studentId);

  Future<List<EvaluationSummaryEntity>> fetchEvaluations(
    int teachingPeriodId,
  ) => _repository.getEvaluations(teachingPeriodId);

  Future<AppException?> saveObservation(
    int teachingPeriodId,
    int studentId,
    String text,
  ) => _guard(() async {
    await _repository.saveObservation(teachingPeriodId, studentId, text);
    await loadReport(teachingPeriodId, studentId, silent: true);
  });

  Future<AppException?> saveRubric(
    GradeDetailEntity detail,
    List<RubricCriterionInput> criteria,
  ) => _guard(() async {
    await _repository.saveRubric(detail.evaluation.evaluationId, criteria);
    await _refresh(detail);
  });

  Future<AppException?> deleteRubric(GradeDetailEntity detail) =>
      _guard(() async {
        await _repository.deleteRubric(detail.evaluation.evaluationId);
        await _refresh(detail);
      });

  Future<AppException?> scoreWithRubric(
    GradeDetailEntity detail, {
    required Map<int, double> scores,
    String? comment,
  }) => _guard(() async {
    _detail = DetailViewState.success(
      await _repository.scoreWithRubric(
        detail.evaluation.evaluationId,
        detail.student.id,
        scores: scores,
        comment: comment,
      ),
    );
    notifyListeners();
    await _refreshReport(detail);
  });

  Future<AppException?> saveActivityGrade(
    GradeDetailEntity detail, {
    required double grade,
    String? comment,
  }) => _guard(() async {
    await _repository.saveActivityGrade(
      detail.evaluation.activityId!,
      detail.student.id,
      grade: grade,
      comment: comment,
    );
    await _refresh(detail);
  });

  Future<AppException?> uploadAttachment(
    GradeDetailEntity detail, {
    required List<int> bytes,
    required String fileName,
  }) => _guard(() async {
    await _repository.uploadAttachment(
      detail.evaluation.evaluationId,
      detail.student.id,
      bytes: bytes,
      fileName: fileName,
    );
    await _refresh(detail);
  });

  Future<AppException?> downloadAttachment(GradeDetailEntity detail) =>
      _guard(() async {
        final file = await _repository.downloadAttachment(
          detail.evaluation.evaluationId,
          detail.student.id,
        );
        await Downloads.save(file);
      });

  Future<AppException?> deleteAttachment(GradeDetailEntity detail) =>
      _guard(() async {
        await _repository.deleteAttachment(
          detail.evaluation.evaluationId,
          detail.student.id,
        );
        await _refresh(detail);
      });

  Future<void> _refresh(GradeDetailEntity detail) async {
    await loadDetail(
      detail.evaluation.evaluationId,
      detail.student.id,
      silent: true,
    );
    await _refreshReport(detail);
  }

  /// The open report, if it's this student's in this class.
  Future<void> _refreshReport(GradeDetailEntity detail) async {
    final report = _report.data;
    if (report != null &&
        report.teachingPeriodId == detail.teachingPeriodId &&
        report.student.id == detail.student.id) {
      await loadReport(
        detail.teachingPeriodId,
        detail.student.id,
        silent: true,
      );
    }
  }

  Future<AppException?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
