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

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Spanish weekday name for an ISO weekday (1 = Lunes … 7 = Domingo).
  static String weekdayName(int isoWeekday) => _weekdays[isoWeekday - 1];

  /// "Lunes, 29 de septiembre".
  static String longDayMonth(DateTime value) =>
      '${weekdayName(value.weekday)}, ${value.day} de ${_months[value.month - 1]}';

  /// "sep".
  static String shortMonth(DateTime value) =>
      _months[value.month - 1].substring(0, 3);

  /// "Lun".
  static String shortWeekday(DateTime value) =>
      weekdayName(value.weekday).substring(0, 3);

  /// "28 sep".
  static String shortDayMonth(DateTime value) =>
      '${value.day} ${_months[value.month - 1].substring(0, 3)}';

  /// Short Spanish relative time for recent events: "Hace un momento",
  /// "Hace 12 min", "Hace 3 h", "Ayer", "Hace 4 días", then the date.
  static String relativeTime(DateTime value, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return date(value);
  }

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
