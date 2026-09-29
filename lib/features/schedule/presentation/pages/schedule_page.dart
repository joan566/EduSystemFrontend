import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/schedule_desktop_view.dart';
import '../mobile/schedule_mobile_view.dart';
import '../providers/schedule_provider.dart';
import '../shared/schedule_week.dart';

/// The teacher's agenda, one week (Monday–Sunday) at a time.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Lives here so the week shown survives a mobile <-> desktop switch.
  DateTime _weekStart = mondayOf(DateTime.now());
  DateTime _selectedDay = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<ScheduleProvider>().loadCalendar(
    from: _weekStart,
    to: _weekStart.add(const Duration(days: 6)),
  );

  /// Shows [day]'s week with [day] selected; reloads only if the week
  /// changed.
  void _showDay(DateTime day) {
    final weekStart = mondayOf(day);
    final weekChanged = !isSameDay(weekStart, _weekStart);
    setState(() {
      _weekStart = weekStart;
      _selectedDay = DateTime(day.year, day.month, day.day);
    });
    if (weekChanged) _load();
  }

  void _shiftWeek(int weeks) => _showDay(
    DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day + 7 * weeks,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final week = ScheduleWeek(
      start: _weekStart,
      selectedDay: _selectedDay,
      onSelectDay: _showDay,
      onPrevious: () => _shiftWeek(-1),
      onNext: () => _shiftWeek(1),
      onToday: () => _showDay(_today()),
      onRetry: _load,
    );
    return ResponsiveBuilder(
      mobile: (_) => ScheduleMobileView(week: week),
      desktop: (_) => ScheduleDesktopView(week: week),
    );
  }
}
