import 'package:flutter/material.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/dashboard_desktop_view.dart';
import '../desktop/widgets/dashboard_desktop_skeleton.dart';
import '../mobile/dashboard_mobile_view.dart';
import '../mobile/widgets/dashboard_mobile_skeleton.dart';
import '../shared/dashboard_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SyncedDataState<DashboardPage> {
  @override
  void ensureData() => ensureDashboardData(context);

  @override
  Widget build(BuildContext context) {
    if (!watchDashboardSettled(context)) {
      return ResponsiveBuilder(
        mobile: (_) => const DashboardMobileSkeleton(),
        desktop: (_) => const DashboardDesktopSkeleton(),
      );
    }
    return ResponsiveBuilder(
      mobile: (_) => const DashboardMobileView(),
      desktop: (_) => const DashboardDesktopView(),
    );
  }
}
