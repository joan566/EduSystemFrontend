import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/academic_levels_desktop_view.dart';
import '../mobile/academic_levels_mobile_view.dart';
import '../providers/academic_levels_provider.dart';

class AcademicLevelsPage extends StatefulWidget {
  const AcademicLevelsPage({super.key});

  @override
  State<AcademicLevelsPage> createState() => _AcademicLevelsPageState();
}

class _AcademicLevelsPageState extends State<AcademicLevelsPage> {
  // Lives here so the search survives a mobile <-> desktop switch.
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicLevelsProvider>().load();
      // Your courses and classes in each level.
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AcademicLevelsMobileView(
        search: _search,
        onSearchChanged: (s) => setState(() => _search = s),
      ),
      desktop: (_) => AcademicLevelsDesktopView(
        search: _search,
        onSearchChanged: (s) => setState(() => _search = s),
      ),
    );
  }
}
