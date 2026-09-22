import 'package:intl/intl.dart';

/// Centralized formatting so date/number/grade presentation is consistent
/// across every feature. Never format dates or grades ad hoc in widgets.
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('d MMM y');
  static final DateFormat _dateTimeFormat = DateFormat('d MMM y, HH:mm');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// Parses a backend `LocalDate` string ("2026-09-21").
  static DateTime parseApiDate(String value) => DateTime.parse(value);

  /// Formats a [DateTime] as a backend `LocalDate` string.
  static String toApiDate(DateTime value) => _apiDate.format(value);

  /// Parses a backend `LocalDateTime` string ("2026-09-21T10:30:00"),
  /// which carries no timezone and is treated as local time.
  static DateTime parseApiDateTime(String value) => DateTime.parse(value);

  static String toApiDateTime(DateTime value) =>
      DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
      ).toIso8601String();

  /// Formats a grade against its scale, e.g. "4.25 / 5.00" or "85 / 100".
  /// Never hardcode a "/5.0" suffix — always pass the scale's bounds.
  static String grade(num value, num maximum, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)} / ${maximum.toStringAsFixed(decimals)}';
  }

  static String percentage(num value, {int decimals = 0}) =>
      '${value.toStringAsFixed(decimals)}%';

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
