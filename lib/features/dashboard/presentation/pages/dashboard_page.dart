import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../desktop/dashboard_desktop_view.dart';
import '../mobile/dashboard_mobile_view.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<DashboardProvider>().loaded) {
      return const Scaffold(body: AppLoading());
    }
    return ResponsiveBuilder(
      mobile: (_) => const DashboardMobileView(),
      desktop: (_) => const DashboardDesktopView(),
    );
  }
}
