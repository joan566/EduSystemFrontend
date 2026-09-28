import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../domain/entities/schedule_entities.dart';

/// The teacher's agenda (today, the coming week, an arbitrary calendar
/// range) and each class's weekly blocks.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider(this._repository);

  final ScheduleRepository _repository;

  DetailViewState<DayScheduleEntity> _today = const DetailViewState();
  DetailViewState<DayScheduleEntity> get today => _today;

  /// The next 7 days — the dashboard counts weekly sessions per class.
  DetailViewState<ScheduleRangeEntity> _week = const DetailViewState();
  DetailViewState<ScheduleRangeEntity> get week => _week;

  /// Whatever range the calendar screen is showing.
  DetailViewState<ScheduleRangeEntity> _calendar = const DetailViewState();
  DetailViewState<ScheduleRangeEntity> get calendar => _calendar;

  final Map<int, ListViewState<ClassScheduleEntity>> _classSchedules = {};
  ListViewState<ClassScheduleEntity> classSchedules(int teachingPeriodId) =>
      _classSchedules[teachingPeriodId] ?? const ListViewState();

  Future<void> loadToday() async {
    _today = DetailViewState.loading();
    notifyListeners();
    try {
      _today = DetailViewState.success(await _repository.getToday());
    } on AppException catch (e) {
      _today = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> loadWeek() async {
    _week = DetailViewState.loading();
    notifyListeners();
    try {
      _week = DetailViewState.success(await _repository.getRange());
    } on AppException catch (e) {
      _week = DetailViewState.error(e);
    }
    notifyListeners();
  }

  /// Omitting [from]/[to] lets the server default to 7 days from today.
  Future<void> loadCalendar({DateTime? from, DateTime? to}) async {
    _calendar = DetailViewState.loading();
    notifyListeners();
    try {
      _calendar = DetailViewState.success(
        await _repository.getRange(from: from, to: to),
      );
    } on AppException catch (e) {
      _calendar = DetailViewState.error(e);
    }
    notifyListeners();
  }

  Future<void> loadClassSchedules(int teachingPeriodId) async {
    _classSchedules[teachingPeriodId] = ListViewState.loading();
    notifyListeners();
    try {
      _classSchedules[teachingPeriodId] = ListViewState.list(
        await _repository.getClassSchedules(teachingPeriodId),
      );
    } on AppException catch (e) {
      _classSchedules[teachingPeriodId] = ListViewState.error(e);
    }
    notifyListeners();
  }

  /// Creates ([scheduleId] null) or updates a weekly block, then refreshes
  /// that class and the agenda views that already loaded.
  Future<AppException?> saveClassSchedule(
    int teachingPeriodId, {
    int? scheduleId,
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) async {
    try {
      await _repository.saveClassSchedule(
        teachingPeriodId,
        scheduleId: scheduleId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );
    } on AppException catch (e) {
      return e;
    }
    await _refreshAfterChange(teachingPeriodId);
    return null;
  }

  Future<AppException?> deleteClassSchedule(
    int teachingPeriodId,
    int scheduleId,
  ) async {
    try {
      await _repository.deleteClassSchedule(teachingPeriodId, scheduleId);
    } on AppException catch (e) {
      return e;
    }
    await _refreshAfterChange(teachingPeriodId);
    return null;
  }

  Future<void> _refreshAfterChange(int teachingPeriodId) => Future.wait([
    loadClassSchedules(teachingPeriodId),
    if (_today.status != DetailStatus.initial) loadToday(),
    if (_week.status != DetailStatus.initial) loadWeek(),
  ]);
}
