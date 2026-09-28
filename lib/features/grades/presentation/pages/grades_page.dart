import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../desktop/grades_desktop_view.dart';
import '../mobile/grades_mobile_view.dart';
import '../providers/grading_provider.dart';
import '../shared/grading_configuration_controller.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  // Selected class and its editable configuration live here so both
  // survive a mobile <-> desktop switch.
  TeachingPeriodEntity? _period;
  GradingConfigurationController? _config;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    _config?.dispose();
    final config = period == null
        ? null
        : GradingConfigurationController(period.id);
    setState(() {
      _period = period;
      _config = config;
    });
    config?.load(context.read<GradingProvider>());
  }

  @override
  void dispose() {
    _config?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => GradesMobileView(
        period: _period,
        config: _config,
        onPeriodChanged: _onPeriodChanged,
      ),
      desktop: (_) => GradesDesktopView(
        period: _period,
        config: _config,
        onPeriodChanged: _onPeriodChanged,
      ),
    );
  }
}
