import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/exam_entity.dart';

class ExamsProvider extends ChangeNotifier {
  ExamsProvider(this._repository);

  final ExamRepository _repository;
  int? _teachingPeriodId;

  ListViewState<ExamSummaryEntity> _state = const ListViewState();
  ListViewState<ExamSummaryEntity> get state => _state;

  DetailViewState<ExamEntity> _detailState = const DetailViewState();
  DetailViewState<ExamEntity> get detailState => _detailState;

  Future<void> load({required int teachingPeriodId, int page = 0}) async {
    _teachingPeriodId = teachingPeriodId;
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(
        teachingPeriodId: teachingPeriodId,
        page: page,
      );
      _state = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _state = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<ExamEntity?> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    required int numberOfQuestions,
  }) async {
    try {
      final exam = await _repository.create(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        numberOfQuestions: numberOfQuestions,
      );
      if (_teachingPeriodId == teachingPeriodId)
        await load(teachingPeriodId: teachingPeriodId);
      return exam;
    } on AppException catch (e) {
      _lastError = e;
      return null;
    }
  }

  AppException? _lastError;
  AppException? get lastError => _lastError;

  Future<void> loadDetail(int examId) async {
    _detailState = DetailViewState.loading();
    notifyListeners();
    try {
      final exam = await _repository.getById(examId);
      _detailState = DetailViewState.success(exam);
    } on AppException catch (e) {
      _detailState = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> updateMetadata(
    int examId, {
    required String name,
    String? description,
    DateTime? evaluationDate,
  }) async {
    try {
      final exam = await _repository.update(
        examId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
      );
      _detailState = DetailViewState.success(exam);
      notifyListeners();
      _reloadListFor(exam.teachingPeriodId);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> saveQuestions(
    int examId,
    List<ExamQuestion> questions,
  ) async {
    try {
      final exam = await _repository.replaceQuestions(examId, questions);
      _detailState = DetailViewState.success(exam);
      notifyListeners();
      _reloadListFor(exam.teachingPeriodId);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  /// Keeps the list (name, date, readiness) in step with detail edits, so
  /// going back shows the current state.
  void _reloadListFor(int teachingPeriodId) {
    if (_teachingPeriodId == teachingPeriodId) {
      load(teachingPeriodId: teachingPeriodId, page: _state.page);
    }
  }

  Future<AppException?> delete(int examId) async {
    try {
      await _repository.delete(examId);
      if (_teachingPeriodId != null)
        await load(teachingPeriodId: _teachingPeriodId!);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<BinaryDownload> downloadAnswerSheet(int examId, int studentId) =>
      _repository.getAnswerSheet(examId, studentId);

  Future<BinaryDownload> downloadAnswerSheets(int examId) =>
      _repository.getAnswerSheets(examId);
}
