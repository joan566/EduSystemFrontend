import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../desktop/exams_desktop_view.dart';
import '../mobile/exams_mobile_view.dart';
import '../providers/exams_provider.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  // Lives here so the selected class survives a mobile <-> desktop switch.
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null) {
      context.read<ExamsProvider>().load(teachingPeriodId: period.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) =>
          ExamsMobileView(period: _period, onPeriodChanged: _onPeriodChanged),
      desktop: (_) =>
          ExamsDesktopView(period: _period, onPeriodChanged: _onPeriodChanged),
    );
  }
}
