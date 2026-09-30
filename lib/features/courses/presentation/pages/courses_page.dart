import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
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

class _CoursesPageState extends State<CoursesPage>
    with SyncedDataState<CoursesPage> {
  // Live here so they survive a mobile <-> desktop switch. Filtering and
  // paging happen in memory over the whole course catalog.
  late CourseFilters _filters = CourseFilters(gradeId: widget.initialGradeId);
  int _page = 0;

  @override
  void ensureData() {
    context.read<CoursesProvider>().ensure();
    context.read<AcademicLevelsProvider>().ensure();
    // Classes, subjects and students per course come from here.
    context.read<TeachingProvider>().ensureAllPeriodsLoaded();
  }

  void _onFiltersChanged(CourseFilters filters) => setState(() {
    _filters = filters;
    _page = 0;
  });

  void _onPageChanged(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => CoursesMobileView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
      desktop: (_) => CoursesDesktopView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
