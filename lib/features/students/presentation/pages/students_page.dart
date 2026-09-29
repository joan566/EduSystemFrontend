import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _StudentsPageState extends State<StudentsPage> {
  // Lives here so the filters survive a mobile <-> desktop switch.
  StudentListFilters _filters = const StudentListFilters();

  /// Student highlighted in the desktop table / preview pane.
  int? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start unfiltered, whatever another screen left in the provider.
      context.read<StudentsProvider>().applyFilters();
      // The course filter options come from the teacher's classes.
      context.read<TeachingProvider>().ensureAllPeriodsLoaded();
    });
  }

  void _onFiltersChanged(StudentListFilters filters) {
    final reload =
        filters.groupId != _filters.groupId ||
        filters.search != _filters.search;
    setState(() => _filters = filters);
    if (reload) {
      context.read<StudentsProvider>().applyFilters(
        groupId: filters.groupId,
        search: filters.search,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => StudentsMobileView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
      desktop: (_) => StudentsDesktopView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        selectedStudentId: _selectedStudentId,
        onSelect: (id) => setState(() => _selectedStudentId = id),
      ),
    );
  }
}
