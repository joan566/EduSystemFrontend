import '../../../../core/utils/formatters.dart';
import '../../domain/entities/schedule_entities.dart';

const _isoDays = {
  'MONDAY': 1,
  'TUESDAY': 2,
  'WEDNESDAY': 3,
  'THURSDAY': 4,
  'FRIDAY': 5,
  'SATURDAY': 6,
  'SUNDAY': 7,
};

int isoDayFromJson(String value) => _isoDays[value]!;

String isoDayToJson(int isoDay) =>
    _isoDays.entries.firstWhere((e) => e.value == isoDay).key;

class ClassScheduleModel {
  static ClassScheduleEntity fromJson(Map<String, dynamic> json) =>
      ClassScheduleEntity(
        id: json['id'] as int,
        teachingPeriodId: json['teachingPeriodId'] as int,
        dayOfWeek: isoDayFromJson(json['dayOfWeek'] as String),
        startTime: ClockTime.parse(json['startTime'] as String),
        endTime: ClockTime.parse(json['endTime'] as String),
        room: json['room'] as String?,
      );
}

class ScheduledClassModel {
  static ScheduledClassEntity fromJson(Map<String, dynamic> json) =>
      ScheduledClassEntity(
        scheduleId: json['scheduleId'] as int,
        teachingPeriodId: json['teachingPeriodId'] as int,
        subjectId: json['subjectId'] as int,
        subjectName: json['subjectName'] as String,
        groupId: json['groupId'] as int,
        gradeName: json['gradeName'] as String,
        groupName: json['groupName'] as String,
        academicPeriodName: json['academicPeriodName'] as String,
        startTime: ClockTime.parse(json['startTime'] as String),
        endTime: ClockTime.parse(json['endTime'] as String),
        room: json['room'] as String?,
      );
}

List<ScheduledClassEntity> _classes(Object? json) => [
  for (final c in json as List<dynamic>)
    ScheduledClassModel.fromJson(c as Map<String, dynamic>),
];

class DayScheduleModel {
  /// `GET /schedule/today`.
  static DayScheduleEntity fromTodayJson(Map<String, dynamic> json) =>
      DayScheduleEntity(
        date: Formatters.parseApiDate(json['date'] as String),
        serverTime: Formatters.parseApiDateTime(json['serverTime'] as String),
        classes: _classes(json['classes']),
      );
}

class ScheduleRangeModel {
  /// `GET /schedule?from=&to=`.
  static ScheduleRangeEntity fromJson(Map<String, dynamic> json) {
    final serverTime = Formatters.parseApiDateTime(
      json['serverTime'] as String,
    );
    return ScheduleRangeEntity(
      from: Formatters.parseApiDate(json['from'] as String),
      to: Formatters.parseApiDate(json['to'] as String),
      serverTime: serverTime,
      days: [
        for (final d in json['days'] as List<dynamic>)
          DayScheduleEntity(
            date: Formatters.parseApiDate(
              (d as Map<String, dynamic>)['date'] as String,
            ),
            serverTime: serverTime,
            classes: _classes(d['classes']),
          ),
      ],
    );
  }
}
