import 'package:edusistem_front/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.grade', () {
    test('formats a value against an arbitrary scale, never hardcoding /5.0', () {
      expect(Formatters.grade(4.25, 5), '4.25 / 5.00');
      expect(Formatters.grade(85, 100, decimals: 0), '85 / 100');
    });
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
}
