import 'package:edusistem_front/features/schedule/data/models/schedule_models.dart';
import 'package:edusistem_front/features/schedule/domain/entities/schedule_entities.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _classJson(
  int scheduleId,
  int periodId,
  String start,
  String end,
) => {
  'scheduleId': scheduleId,
  'teachingPeriodId': periodId,
  'subjectId': periodId,
  'subjectName': 'Materia $periodId',
  'groupId': 1,
  'gradeName': '5°',
  'groupName': 'A',
  'academicPeriodName': '2026-2',
  'startTime': start,
  'endTime': end,
  'room': null,
};

DayScheduleEntity _today(String serverTime) => DayScheduleModel.fromTodayJson({
  'date': '2026-09-29',
  'serverTime': serverTime,
  'timezone': 'America/Bogota',
  'classes': [
    _classJson(1, 10, '07:00', '08:00'),
    _classJson(2, 11, '08:00', '09:00'),
    _classJson(3, 12, '09:00', '10:00'),
  ],
});

void main() {
  group('ClockTime', () {
    test('parses HH:mm and ignores seconds', () {
      expect(ClockTime.parse('07:05').format(), '07:05');
      expect(ClockTime.parse('13:30:00'), const ClockTime(13, 30));
    });
  });

  group('DayScheduleEntity status (server clock)', () {
    test('marks finished, in progress and upcoming classes', () {
      final day = _today('2026-09-29T08:15:00');
      expect(day.statusOf(day.classes[0]), ScheduledClassStatus.finished);
      expect(day.statusOf(day.classes[1]), ScheduledClassStatus.inProgress);
      expect(day.statusOf(day.classes[2]), ScheduledClassStatus.upcoming);
    });

    test('a class ending exactly now is finished; back-to-back is fine', () {
      final day = _today('2026-09-29T08:00:00');
      expect(day.statusOf(day.classes[0]), ScheduledClassStatus.finished);
      expect(day.statusOf(day.classes[1]), ScheduledClassStatus.inProgress);
    });

    test('nextClass prefers the class in progress, else the next one', () {
      expect(_today('2026-09-29T08:15:00').nextClass!.scheduleId, 2);
      expect(_today('2026-09-29T06:00:00').nextClass!.scheduleId, 1);
      expect(_today('2026-09-29T11:00:00').nextClass, isNull);
    });
  });

  group('ScheduleRangeModel', () {
    test('parses days and counts weekly sessions per class', () {
      final range = ScheduleRangeModel.fromJson({
        'from': '2026-09-28',
        'to': '2026-09-30',
        'serverTime': '2026-09-28T10:00:00',
        'timezone': 'America/Bogota',
        'days': [
          {
            'date': '2026-09-28',
            'dayOfWeek': 'MONDAY',
            'classes': [_classJson(1, 10, '07:00', '08:00')],
          },
          {'date': '2026-09-29', 'dayOfWeek': 'TUESDAY', 'classes': []},
          {
            'date': '2026-09-30',
            'dayOfWeek': 'WEDNESDAY',
            'classes': [
              _classJson(4, 10, '07:00', '08:00'),
              _classJson(5, 11, '09:00', '10:00'),
            ],
          },
        ],
      });
      expect(range.days, hasLength(3));
      expect(range.days[1].classes, isEmpty);
      expect(range.occurrencesByTeachingPeriod, {10: 2, 11: 1});
    });
  });

  group('day of week mapping', () {
    test('round-trips ISO weekdays with the API enum', () {
      expect(isoDayFromJson('MONDAY'), DateTime.monday);
      expect(isoDayToJson(DateTime.sunday), 'SUNDAY');
    });
  });

  group('nextClassOccurrence', () {
    const monday7 = ClassScheduleEntity(
      id: 1,
      teachingPeriodId: 1,
      dayOfWeek: DateTime.monday,
      startTime: ClockTime(7, 0),
      endTime: ClockTime(8, 0),
    );
    const wednesday10 = ClassScheduleEntity(
      id: 2,
      teachingPeriodId: 1,
      dayOfWeek: DateTime.wednesday,
      startTime: ClockTime(10, 0),
      endTime: ClockTime(11, 0),
    );
    // Monday 2026-09-28.
    final monday = DateTime(2026, 9, 28);

    test('returns the block in progress today', () {
      final next = nextClassOccurrence([
        monday7,
        wednesday10,
      ], monday.add(const Duration(hours: 7, minutes: 30)));
      expect(next!.block.id, 1);
      expect(next.date, monday);
    });

    test('skips blocks already over and finds the next day', () {
      final next = nextClassOccurrence([
        monday7,
        wednesday10,
      ], monday.add(const Duration(hours: 9)));
      expect(next!.block.id, 2);
      expect(next.date, DateTime(2026, 9, 30));
    });

    test('wraps to next week', () {
      final next = nextClassOccurrence([
        monday7,
      ], monday.add(const Duration(hours: 9)));
      expect(next!.date, DateTime(2026, 10, 5));
    });

    test('stops at the class end date', () {
      final next = nextClassOccurrence(
        [monday7],
        monday.add(const Duration(hours: 9)),
        lastDate: DateTime(2026, 10, 1),
      );
      expect(next, isNull);
    });
  });
}
