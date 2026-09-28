import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/academic_levels_desktop_view.dart';
import '../mobile/academic_levels_mobile_view.dart';
import '../providers/academic_levels_provider.dart';

class AcademicLevelsPage extends StatefulWidget {
  const AcademicLevelsPage({super.key});

  @override
  State<AcademicLevelsPage> createState() => _AcademicLevelsPageState();
}

class _AcademicLevelsPageState extends State<AcademicLevelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AcademicLevelsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => const AcademicLevelsMobileView(),
      desktop: (_) => const AcademicLevelsDesktopView(),
    );
  }
}
