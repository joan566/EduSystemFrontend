import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_entity.dart';

/// A class's attendance sessions (most recent first) and the attendance of
/// one class on one date, which is what the screen marks.
class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._repository);

  final AttendanceRepository _repository;

  ListViewState<AttendanceSessionEntity> _state = const ListViewState();
  ListViewState<AttendanceSessionEntity> get state => _state;

  /// One class's attendance on one date.
  DetailViewState<AttendanceDayEntity> _day = const DetailViewState();
  DetailViewState<AttendanceDayEntity> get day => _day;

  Future<void> load({required int teachingPeriodId, int page = 0}) async {
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

  int _dayRequest = 0;

  Future<AttendanceDayEntity?> loadDay({
    required int teachingPeriodId,
    required DateTime date,
  }) async {
    final request = ++_dayRequest;
    _day = DetailViewState.loading();
    notifyListeners();
    try {
      final day = await _repository.getDay(
        teachingPeriodId: teachingPeriodId,
        date: date,
      );
      // A newer request (another class or date) may have started meanwhile.
      if (request != _dayRequest) return null;
      _day = DetailViewState.success(day);
      notifyListeners();
      return day;
    } on AppException catch (e) {
      if (request != _dayRequest) return null;
      _day = DetailViewState.error(e);
      notifyListeners();
      return null;
    }
  }

  /// Saves [records] for the loaded day, creating that day's session first
  /// if it doesn't exist yet.
  Future<AppException?> saveDay(
    List<({int studentId, AttendanceStatus status, String? observation})>
    records,
  ) async {
    final day = _day.data;
    if (day == null) return null;
    try {
      final session =
          day.session ??
          await _repository.create(
            teachingPeriodId: day.teachingPeriodId,
            sessionDate: day.date,
          );
      final detail = await _repository.putRecords(session.id, records);
      final current = _day.data;
      if (current != null &&
          current.teachingPeriodId == day.teachingPeriodId &&
          current.date == day.date) {
        _day = DetailViewState.success(
          AttendanceDayEntity(
            teachingPeriodId: day.teachingPeriodId,
            date: day.date,
            session: detail.session,
            students: detail.students,
          ),
        );
        notifyListeners();
      }
      if (day.session == null && _state.status != ViewStatus.initial) {
        await load(teachingPeriodId: day.teachingPeriodId);
      }
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
