import 'package:edusistem_front/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.grade', () {
    test(
      'formats a value against an arbitrary scale, never hardcoding /5.0',
      () {
        expect(Formatters.grade(4.25, 5), '4.25 / 5.00');
        expect(Formatters.grade(85, 100, decimals: 0), '85 / 100');
      },
    );
  });

  group('Formatters API date round-trip', () {
    test('toApiDate/parseApiDate round-trip a LocalDate', () {
      final date = DateTime(2026, 9, 21);
      final serialized = Formatters.toApiDate(date);
      expect(serialized, '2026-09-21');
      expect(Formatters.parseApiDate(serialized), date);
    });
  });

  group('Formatters.fileSize', () {
    test('formats bytes, kilobytes and megabytes', () {
      expect(Formatters.fileSize(500), '500 B');
      expect(Formatters.fileSize(2048), '2.0 KB');
      expect(Formatters.fileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });

  group('Formatters.relativeTime', () {
    final now = DateTime(2026, 9, 28, 12);

    test('uses minutes, hours and days for recent events', () {
      expect(Formatters.relativeTime(now, now: now), 'Hace un momento');
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(minutes: 12)),
          now: now,
        ),
        'Hace 12 min',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        'Hace 3 h',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(days: 1)),
          now: now,
        ),
        'Ayer',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(days: 4)),
          now: now,
        ),
        'Hace 4 días',
      );
    });

    test('falls back to the date after a week', () {
      final old = now.subtract(const Duration(days: 10));
      expect(Formatters.relativeTime(old, now: now), Formatters.date(old));
    });
  });

  group('Formatters Spanish dates', () {
    test('longDayMonth names the weekday and month in Spanish', () {
      expect(
        Formatters.longDayMonth(DateTime(2026, 9, 28)),
        'Lunes, 28 de septiembre',
      );
      expect(
        Formatters.longDayMonth(DateTime(2026, 3, 1)),
        'Domingo, 1 de marzo',
      );
    });

    test('shortDayMonth abbreviates the month', () {
      expect(Formatters.shortDayMonth(DateTime(2026, 10, 4)), '4 oct');
    });

    test('weekdayName uses ISO numbering', () {
      expect(Formatters.weekdayName(DateTime.monday), 'Lunes');
      expect(Formatters.weekdayName(DateTime.sunday), 'Domingo');
    });
  });
}
