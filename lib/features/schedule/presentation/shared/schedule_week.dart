import 'package:flutter/foundation.dart';

import '../../../../core/utils/formatters.dart';

/// Monday of [date]'s week (dates only, no time).
DateTime mondayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The week the calendar shows and how to move it. Built by the page entry
/// point and handed to either view.
class ScheduleWeek {
  const ScheduleWeek({
    required this.start,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onRetry,
  });

  final DateTime start;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onRetry;

  DateTime get end => start.add(const Duration(days: 6));

  bool get isCurrent => isSameDay(start, mondayOf(DateTime.now()));

  /// "28 sep – 4 oct".
  String get label =>
      '${Formatters.shortDayMonth(start)} – ${Formatters.shortDayMonth(end)}';
}
