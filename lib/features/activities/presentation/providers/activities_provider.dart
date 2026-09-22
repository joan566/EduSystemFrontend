import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/activity_repository.dart';
import '../../domain/entities/activity_entity.dart';

class ActivitiesProvider extends ChangeNotifier {
  ActivitiesProvider(this._repository);

  final ActivityRepository _repository;

  ListViewState<ActivityEntity> _state = const ListViewState();
  ListViewState<ActivityEntity> get state => _state;

  DetailViewState<ActivityEntity> _detailState = const DetailViewState();
  DetailViewState<ActivityEntity> get detailState => _detailState;

  ListViewState<StudentGradeEntity> _gradesState = const ListViewState();
  ListViewState<StudentGradeEntity> get gradesState => _gradesState;

  Future<void> load({required int teachingPeriodId, int page = 0}) async {
    _state = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPage(teachingPeriodId: teachingPeriodId, page: page);
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

  Future<ActivityEntity?> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    required double maximumScore,
    String? activityType,
  }) async {
    try {
      final activity = await _repository.create(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        activityType: activityType,
      );
      await load(teachingPeriodId: teachingPeriodId);
      return activity;
    } on AppException catch (e) {
      _lastError = e;
      return null;
    }
  }

  AppException? _lastError;
  AppException? get lastError => _lastError;

  Future<void> loadDetail(int id) async {
    _detailState = DetailViewState.loading();
    notifyListeners();
    try {
      final activity = await _repository.getById(id);
      _detailState = DetailViewState.success(activity);
      await loadGrades(id);
    } on AppException catch (e) {
      _detailState = DetailViewState.error(e);
      notifyListeners();
    }
  }

  Future<void> loadGrades(int activityId) async {
    _gradesState = ListViewState.loading();
    notifyListeners();
    try {
      final grades = await _repository.getGrades(activityId);
      _gradesState = ListViewState.list(grades);
    } on AppException catch (e) {
      _gradesState = ListViewState.error(e);
    }
    notifyListeners();
  }

  /// Saves every edited grade in a single request (§99: batch save,
  /// mirroring the attendance roster pattern — not one round trip per
  /// student).
  Future<AppException?> saveGrades(
    int activityId,
    List<({int studentId, double grade, String? comment})> grades,
  ) async {
    try {
      final result = await _repository.putGrades(activityId, grades);
      _gradesState = ListViewState.list(result);
      notifyListeners();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> delete(int id, {required int teachingPeriodId}) async {
    try {
      await _repository.delete(id);
      await load(teachingPeriodId: teachingPeriodId);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
