import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/teaching_repository.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import '../../domain/entities/teaching_period_entity.dart';
import '../../domain/entities/teaching_period_summary_entity.dart';

/// Owns both teaching assignments (group + subject) and teaching periods
/// (assignment + academic period) — the two are tightly coupled (§4) and
/// splitting them into separate providers would just duplicate wiring.
class TeachingProvider extends ChangeNotifier {
  TeachingProvider(this._repository);

  final TeachingRepository _repository;

  ListViewState<TeachingAssignmentEntity> _assignmentsState = const ListViewState();
  ListViewState<TeachingAssignmentEntity> get assignmentsState => _assignmentsState;

  ListViewState<TeachingPeriodEntity> _periodsState = const ListViewState();
  ListViewState<TeachingPeriodEntity> get periodsState => _periodsState;

  /// Flat list of every teaching period, used by other features (exams,
  /// activities, attendance, grading) to let the teacher pick which class
  /// they're working with (`teachingPeriodId` is a required query param
  /// across the API).
  /// The class open on the class detail screen.
  DetailViewState<TeachingPeriodEntity> _periodDetail = const DetailViewState();
  DetailViewState<TeachingPeriodEntity> get periodDetail => _periodDetail;

  Future<void> loadPeriodDetail(int id) async {
    _periodDetail = DetailViewState.loading();
    notifyListeners();
    try {
      _periodDetail = DetailViewState.success(await _repository.getPeriod(id));
    } on AppException catch (e) {
      _periodDetail = DetailViewState.error(e);
    }
    notifyListeners();
  }

  final Map<int, DetailViewState<TeachingPeriodSummaryEntity>> _summaries = {};

  /// Grading progress and counts of one class.
  DetailViewState<TeachingPeriodSummaryEntity> periodSummary(int id) =>
      _summaries[id] ?? const DetailViewState();

  Future<void> loadPeriodSummary(int id) async {
    _summaries[id] = DetailViewState.loading();
    notifyListeners();
    try {
      _summaries[id] = DetailViewState.success(
        await _repository.getPeriodSummary(id),
      );
    } on AppException catch (e) {
      _summaries[id] = DetailViewState.error(e);
    }
    notifyListeners();
  }

  List<TeachingPeriodEntity> _allPeriods = [];
  List<TeachingPeriodEntity> get allPeriods => _allPeriods;
  bool _allPeriodsLoaded = false;

  Future<void> loadAssignments({int page = 0, int? groupId, int? subjectId, bool? active}) async {
    _assignmentsState = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getAssignments(
        page: page,
        groupId: groupId,
        subjectId: subjectId,
        active: active,
      );
      _assignmentsState = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _assignmentsState = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> createAssignment({required int groupId, required int subjectId}) async {
    try {
      await _repository.createAssignment(groupId: groupId, subjectId: subjectId);
      await loadAssignments();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> setAssignmentActive(int id, bool active) async {
    try {
      await _repository.setAssignmentActive(id, active);
      await loadAssignments(page: _assignmentsState.page);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> deleteAssignment(int id) async {
    try {
      await _repository.deleteAssignment(id);
      await loadAssignments(page: _assignmentsState.page);
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<void> loadPeriods({int page = 0, int? teachingAssignmentId}) async {
    _periodsState = ListViewState.loading();
    notifyListeners();
    try {
      final result = await _repository.getPeriods(
        page: page,
        teachingAssignmentId: teachingAssignmentId,
      );
      _periodsState = ListViewState.fromPage(
        content: result.content,
        page: result.page,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
      );
    } on AppException catch (e) {
      _periodsState = ListViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> createPeriod({
    required int teachingAssignmentId,
    required int academicPeriodId,
  }) async {
    try {
      await _repository.createPeriod(
        teachingAssignmentId: teachingAssignmentId,
        academicPeriodId: academicPeriodId,
      );
      _allPeriodsLoaded = false;
      await loadPeriods(teachingAssignmentId: teachingAssignmentId);
      await ensureAllPeriodsLoaded();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> deletePeriod(int id, {int? teachingAssignmentId}) async {
    try {
      await _repository.deletePeriod(id);
      _allPeriodsLoaded = false;
      await loadPeriods(teachingAssignmentId: teachingAssignmentId);
      await ensureAllPeriodsLoaded();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<void> ensureAllPeriodsLoaded({bool forceReload = false}) async {
    if (_allPeriodsLoaded && !forceReload) return;
    try {
      final result = await _repository.getPeriods(page: 0);
      _allPeriods = result.content;
      _allPeriodsLoaded = true;
      notifyListeners();
    } on AppException {
      // Leave whatever was loaded before; callers show their own error UI
      // for the primary list, so this silent fallback only affects
      // pickers elsewhere.
    }
  }
}
