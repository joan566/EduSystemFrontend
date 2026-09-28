/// A wall-clock time without a date ("07:00"), as the schedule API sends it.
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  /// Parses "HH:mm" (seconds, if any, are ignored).
  factory ClockTime.parse(String value) {
    final parts = value.split(':');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// "07:00".
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  DateTime on(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(ClockTime other) => minutesOfDay - other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => format();
}

/// "07:00 – 08:00".
String formatTimeRange(ClockTime start, ClockTime end) =>
    '${start.format()} – ${end.format()}';

/// One weekly block of a class: every [dayOfWeek] (ISO, 1 = lunes) from
/// [startTime] to [endTime].
class ClassScheduleEntity {
  const ClassScheduleEntity({
    required this.id,
    required this.teachingPeriodId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  final int id;
  final int teachingPeriodId;
  final int dayOfWeek;
  final ClockTime startTime;
  final ClockTime endTime;
  final String? room;
}

enum ScheduledClassStatus { finished, inProgress, upcoming }

/// A class occurrence on a specific day of the teacher's agenda.
class ScheduledClassEntity {
  const ScheduledClassEntity({
    required this.scheduleId,
    required this.teachingPeriodId,
    required this.subjectId,
    required this.subjectName,
    required this.groupId,
    required this.gradeName,
    required this.groupName,
    required this.academicPeriodName,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  final int scheduleId;
  final int teachingPeriodId;
  final int subjectId;
  final String subjectName;
  final int groupId;
  final String gradeName;
  final String groupName;
  final String academicPeriodName;
  final ClockTime startTime;
  final ClockTime endTime;
  final String? room;

  String get courseLabel => '$gradeName $groupName';

  /// Status at [now] for an occurrence on [date]. Pass the server's time,
  /// not the device's, so status doesn't depend on the phone's clock.
  ScheduledClassStatus statusAt(DateTime now, DateTime date) {
    if (!now.isBefore(endTime.on(date))) return ScheduledClassStatus.finished;
    if (!now.isBefore(startTime.on(date))) {
      return ScheduledClassStatus.inProgress;
    }
    return ScheduledClassStatus.upcoming;
  }
}

/// The teacher's classes for one day, plus the server's clock.
class DayScheduleEntity {
  const DayScheduleEntity({
    required this.date,
    required this.serverTime,
    required this.classes,
  });

  final DateTime date;
  final DateTime serverTime;

  /// Sorted by start time.
  final List<ScheduledClassEntity> classes;

  ScheduledClassStatus statusOf(ScheduledClassEntity c) =>
      c.statusAt(serverTime, date);

  /// The class in progress, else the next one to start; null when the day
  /// is over (or empty).
  ScheduledClassEntity? get nextClass =>
      classes
          .where((c) => statusOf(c) == ScheduledClassStatus.inProgress)
          .firstOrNull ??
      classes
          .where((c) => statusOf(c) == ScheduledClassStatus.upcoming)
          .firstOrNull;
}

/// A range of days of the teacher's agenda ("Ver calendario").
class ScheduleRangeEntity {
  const ScheduleRangeEntity({
    required this.from,
    required this.to,
    required this.serverTime,
    required this.days,
  });

  final DateTime from;
  final DateTime to;
  final DateTime serverTime;
  final List<DayScheduleEntity> days;

  /// How many times each class (teachingPeriodId) meets in the range.
  Map<int, int> get occurrencesByTeachingPeriod {
    final counts = <int, int>{};
    for (final day in days) {
      for (final c in day.classes) {
        counts.update(c.teachingPeriodId, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }
}
