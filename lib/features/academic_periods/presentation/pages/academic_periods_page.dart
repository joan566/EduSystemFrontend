import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/academic_periods_desktop_view.dart';
import '../mobile/academic_periods_mobile_view.dart';
import '../providers/academic_periods_provider.dart';

class AcademicPeriodsPage extends StatefulWidget {
  const AcademicPeriodsPage({super.key});

  @override
  State<AcademicPeriodsPage> createState() => _AcademicPeriodsPageState();
}

class _AcademicPeriodsPageState extends State<AcademicPeriodsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AcademicPeriodsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => const AcademicPeriodsMobileView(),
      desktop: (_) => const AcademicPeriodsDesktopView(),
    );
  }
}
