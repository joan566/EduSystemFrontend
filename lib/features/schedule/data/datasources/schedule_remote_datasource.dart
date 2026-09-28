import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/schedule_entities.dart';
import '../models/schedule_models.dart';

class ScheduleRemoteDataSource {
  ScheduleRemoteDataSource(this._client);

  final ApiClient _client;

  Future<DayScheduleEntity> getToday({DateTime? date}) async {
    final response = await _client.get(
      ApiEndpoints.scheduleToday,
      queryParameters: {
        'date': date == null ? null : Formatters.toApiDate(date),
      },
    );
    return DayScheduleModel.fromTodayJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ScheduleRangeEntity> getRange({DateTime? from, DateTime? to}) async {
    final response = await _client.get(
      ApiEndpoints.schedule,
      queryParameters: {
        'from': from == null ? null : Formatters.toApiDate(from),
        'to': to == null ? null : Formatters.toApiDate(to),
      },
    );
    return ScheduleRangeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ClassScheduleEntity>> getClassSchedules(
    int teachingPeriodId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.teachingPeriodSchedules(teachingPeriodId),
    );
    return [
      for (final s in response.data as List<dynamic>)
        ClassScheduleModel.fromJson(s as Map<String, dynamic>),
    ];
  }

  Map<String, dynamic> _body({
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) => {
    'dayOfWeek': isoDayToJson(dayOfWeek),
    'startTime': startTime.format(),
    'endTime': endTime.format(),
    'room': room,
  };

  Future<void> createClassSchedule(
    int teachingPeriodId, {
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) => _client.post(
    ApiEndpoints.teachingPeriodSchedules(teachingPeriodId),
    data: _body(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    ),
  );

  Future<void> updateClassSchedule(
    int teachingPeriodId,
    int scheduleId, {
    required int dayOfWeek,
    required ClockTime startTime,
    required ClockTime endTime,
    String? room,
  }) => _client.put(
    ApiEndpoints.teachingPeriodScheduleById(teachingPeriodId, scheduleId),
    data: _body(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    ),
  );

  Future<void> deleteClassSchedule(int teachingPeriodId, int scheduleId) =>
      _client.delete(
        ApiEndpoints.teachingPeriodScheduleById(teachingPeriodId, scheduleId),
      );
}
