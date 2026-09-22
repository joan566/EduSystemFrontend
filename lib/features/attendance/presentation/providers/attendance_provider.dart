import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._repository);

  final AttendanceRepository _repository;

  ListViewState<AttendanceSessionEntity> _state = const ListViewState();
  ListViewState<AttendanceSessionEntity> get state => _state;

  DetailViewState<SessionDetailEntity> _detailState = const DetailViewState();
  DetailViewState<SessionDetailEntity> get detailState => _detailState;

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

  AppException? _lastError;
  AppException? get lastError => _lastError;

  Future<AttendanceSessionEntity?> create({
    required int teachingPeriodId,
    required DateTime sessionDate,
    String? name,
  }) async {
    try {
      final session = await _repository.create(
        teachingPeriodId: teachingPeriodId,
        sessionDate: sessionDate,
        name: name,
      );
      await load(teachingPeriodId: teachingPeriodId);
      return session;
    } on AppException catch (e) {
      _lastError = e;
      return null;
    }
  }

  Future<void> loadDetail(int id) async {
    _detailState = DetailViewState.loading();
    notifyListeners();
    try {
      final detail = await _repository.getById(id);
      _detailState = DetailViewState.success(detail);
    } on AppException catch (e) {
      _detailState = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<AppException?> saveRecords(
    int id,
    List<({int studentId, AttendanceStatus status, String? observation})> records,
  ) async {
    try {
      final detail = await _repository.putRecords(id, records);
      _detailState = DetailViewState.success(detail);
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
