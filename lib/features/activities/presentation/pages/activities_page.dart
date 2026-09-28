import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../desktop/activities_desktop_view.dart';
import '../mobile/activities_mobile_view.dart';
import '../providers/activities_provider.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // Lives here, not in a view, so the selected class survives a
  // mobile <-> desktop switch (e.g. resizing the browser window).
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null) {
      context.read<ActivitiesProvider>().load(teachingPeriodId: period.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => ActivitiesMobileView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
      ),
      desktop: (_) => ActivitiesDesktopView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
      ),
    );
  }
}
