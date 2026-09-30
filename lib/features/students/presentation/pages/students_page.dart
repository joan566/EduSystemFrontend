import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/students_desktop_view.dart';
import '../mobile/students_mobile_view.dart';
import '../providers/students_provider.dart';
import '../shared/student_list_filters.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with SyncedDataState<StudentsPage> {
  // Lives here so the filters survive a mobile <-> desktop switch.
  StudentListFilters _filters = const StudentListFilters();

  /// Student highlighted in the desktop table / preview pane.
  int? _selectedStudentId;

  /// Server page of the listing; back to 0 when the course or search
  /// changes.
  int _page = 0;

  /// The exact listing query already read (page, course, search) comes from
  /// memory.
  @override
  void ensureData() {
    context.read<StudentsProvider>().ensureQuery(
      StudentsProvider.queryOf(
        page: _page,
        groupId: _filters.groupId,
        search: _filters.search,
      ),
    );
    // The course filter options come from the teacher's classes.
    context.read<TeachingProvider>().ensureAllPeriodsLoaded();
  }

  void _onFiltersChanged(StudentListFilters filters) {
    final queryChanged =
        filters.groupId != _filters.groupId ||
        filters.search != _filters.search;
    setState(() {
      _filters = filters;
      if (queryChanged) _page = 0;
    });
    if (queryChanged) ensureData();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    ensureData();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => StudentsMobileView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        page: _page,
        onPageChanged: _onPageChanged,
      ),
      desktop: (_) => StudentsDesktopView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        selectedStudentId: _selectedStudentId,
        onSelect: (id) => setState(() => _selectedStudentId = id),
        page: _page,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
