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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<ScheduleProvider>().loadCalendar(
    from: _weekStart,
    to: _weekStart.add(const Duration(days: 6)),
  );

  void _showWeek(DateTime weekStart) {
    setState(() => _weekStart = weekStart);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final week = ScheduleWeek(
      start: _weekStart,
      onPrevious: () => _showWeek(_weekStart.subtract(const Duration(days: 7))),
      onNext: () => _showWeek(_weekStart.add(const Duration(days: 7))),
      onToday: () => _showWeek(mondayOf(DateTime.now())),
      onRetry: _load,
    );
    return ResponsiveBuilder(
      mobile: (_) => ScheduleMobileView(week: week),
      desktop: (_) => ScheduleDesktopView(week: week),
    );
  }
}
