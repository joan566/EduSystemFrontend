import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/academic_periods_desktop_view.dart';
import '../mobile/academic_periods_mobile_view.dart';
import '../providers/academic_periods_provider.dart';
import '../shared/period_timeline.dart';

class AcademicPeriodsPage extends StatefulWidget {
  const AcademicPeriodsPage({super.key});

  @override
  State<AcademicPeriodsPage> createState() => _AcademicPeriodsPageState();
}

class _AcademicPeriodsPageState extends State<AcademicPeriodsPage> {
  // Lives here so the filter survives a mobile <-> desktop switch.
  PeriodStatusFilter _filter = PeriodStatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicPeriodsProvider>().load();
      // How many of your classes run in each period.
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AcademicPeriodsMobileView(
        filter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
      ),
      desktop: (_) => AcademicPeriodsDesktopView(
        filter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
      ),
    );
  }
}
