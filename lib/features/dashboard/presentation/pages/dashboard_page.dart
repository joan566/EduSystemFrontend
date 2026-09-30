import 'package:flutter/material.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../desktop/dashboard_desktop_view.dart';
import '../mobile/dashboard_mobile_view.dart';
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
      return const Scaffold(body: AppLoading());
    }
    return ResponsiveBuilder(
      mobile: (_) => const DashboardMobileView(),
      desktop: (_) => const DashboardDesktopView(),
    );
  }
}
