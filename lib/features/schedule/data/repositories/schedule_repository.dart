import '../../domain/entities/schedule_entities.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepository {
  ScheduleRepository(this._remote);

  final ScheduleRemoteDataSource _remote;

  Future<DayScheduleEntity> getToday({DateTime? date}) =>
      _remote.getToday(date: date);

  Future<ScheduleRangeEntity> getRange({DateTime? from, DateTime? to}) =>
      _remote.getRange(from: from, to: to);

  Future<List<ClassScheduleEntity>> getClassSchedules(int teachingPeriodId) =>
      _remote.getClassSchedules(teachingPeriodId);

  Future<void> saveClassSchedule(
    int teachingPeriodId, {
    int? scheduleId,
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) => scheduleId == null
      ? _remote.createClassSchedule(
          teachingPeriodId,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          room: room,
        )
      : _remote.updateClassSchedule(
          teachingPeriodId,
          scheduleId,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          room: room,
        );

  Future<void> deleteClassSchedule(int teachingPeriodId, int scheduleId) =>
      _remote.deleteClassSchedule(teachingPeriodId, scheduleId);
}
