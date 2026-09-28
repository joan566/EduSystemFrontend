import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../desktop/attendance_desktop_view.dart';
import '../mobile/attendance_mobile_view.dart';
import '../providers/attendance_provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Lives here, not in a view, so the selected class survives a
  // mobile <-> desktop switch.
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null) {
      context.read<AttendanceProvider>().load(teachingPeriodId: period.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AttendanceMobileView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
      ),
      desktop: (_) => AttendanceDesktopView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
      ),
    );
  }
}
