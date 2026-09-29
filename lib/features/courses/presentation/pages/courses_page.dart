import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/state/list_state.dart';
import '../../../academic_levels/presentation/providers/academic_levels_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/courses_desktop_view.dart';
import '../mobile/courses_mobile_view.dart';
import '../providers/courses_provider.dart';
import '../shared/course_filters.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key, this.initialGradeId});

  /// Level to filter by on open (from Grados académicos, `?gradeId=`).
  final int? initialGradeId;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  // Lives here so the filters survive a mobile <-> desktop switch.
  late CourseFilters _filters = CourseFilters(gradeId: widget.initialGradeId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesProvider>().applyFilters(gradeId: _filters.gradeId);
      final levels = context.read<AcademicLevelsProvider>();
      if (levels.state.status == ViewStatus.initial) levels.load();
      // Classes, subjects and students per course come from here.
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
    });
  }

  void _onFiltersChanged(CourseFilters filters) {
    setState(() => _filters = filters);
    context.read<CoursesProvider>().applyFilters(
      gradeId: filters.gradeId,
      academicYear: filters.academicYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => CoursesMobileView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
      desktop: (_) => CoursesDesktopView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }
}
