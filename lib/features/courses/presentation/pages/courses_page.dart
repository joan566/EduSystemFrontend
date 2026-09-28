import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/state/list_state.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../desktop/courses_desktop_view.dart';
import '../mobile/courses_mobile_view.dart';
import '../providers/courses_provider.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesProvider>().load();
      final levels = context.read<AcademicLevelsProvider>();
      if (levels.state.status == ViewStatus.initial) levels.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => const CoursesMobileView(),
      desktop: (_) => const CoursesDesktopView(),
    );
  }
}
