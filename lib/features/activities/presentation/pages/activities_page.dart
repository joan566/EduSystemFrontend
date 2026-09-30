import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../desktop/activities_desktop_view.dart';
import '../mobile/activities_mobile_view.dart';
import '../providers/activities_provider.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key, this.initialTeachingPeriodId});

  /// Class to preselect (from `?teachingPeriodId=`), e.g. when opened from
  /// a class screen.
  final int? initialTeachingPeriodId;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SyncedDataState<ActivitiesPage> {
  // Live here, not in a view, so the selected class and page survive a
  // mobile <-> desktop switch (e.g. resizing the browser window).
  TeachingPeriodEntity? _period;
  int _page = 0;

  /// A class's activities come from memory after the first visit.
  @override
  void ensureData() {
    final period = _period;
    if (period != null) {
      context.read<ActivitiesProvider>().ensureActivities(period.id);
    }
  }

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() {
      _period = period;
      _page = 0;
    });
    ensureData();
  }

  void _onPageChanged(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => ActivitiesMobileView(
        preferredPeriodId: widget.initialTeachingPeriodId,
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
      desktop: (_) => ActivitiesDesktopView(
        preferredPeriodId: widget.initialTeachingPeriodId,
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
