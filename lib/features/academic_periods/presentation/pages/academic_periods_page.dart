import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
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

class _AcademicPeriodsPageState extends State<AcademicPeriodsPage>
    with SyncedDataState<AcademicPeriodsPage> {
  // Live here so they survive a mobile <-> desktop switch.
  PeriodStatusFilter _filter = PeriodStatusFilter.all;
  int _page = 0;

  @override
  void ensureData() {
    context.read<AcademicPeriodsProvider>().ensure();
    // How many of your classes run in each period.
    context.read<TeachingProvider>().ensureAllPeriodsLoaded();
  }

  void _onFilterChanged(PeriodStatusFilter filter) => setState(() {
    _filter = filter;
    _page = 0;
  });

  void _onPageChanged(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AcademicPeriodsMobileView(
        filter: _filter,
        onFilterChanged: _onFilterChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
      desktop: (_) => AcademicPeriodsDesktopView(
        filter: _filter,
        onFilterChanged: _onFilterChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
