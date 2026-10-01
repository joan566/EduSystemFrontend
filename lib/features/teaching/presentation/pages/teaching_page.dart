import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/state/list_state.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../desktop/teaching_desktop_view.dart';
import '../mobile/teaching_mobile_view.dart';
import '../providers/teaching_provider.dart';
import '../shared/class_lookup.dart';
import '../shared/teaching_actions.dart';

class TeachingPage extends StatefulWidget {
  const TeachingPage({super.key});

  @override
  State<TeachingPage> createState() => _TeachingPageState();
}

class _TeachingPageState extends State<TeachingPage>
    with SyncedDataState<TeachingPage> {
  // Filters, period and search live here so they survive a mobile <->
  // desktop switch.
  AssignmentFilters _filters = const AssignmentFilters();

  /// Academic period the list shows classes for; null = all.
  int? _academicPeriodId;
  String _search = '';

  /// Row selected in the desktop table (its preview shows beside it).
  int? _selectedAssignmentId;

  bool _academicPeriodPicked = false;

  @override
  void ensureData() {
    final teaching = context.read<TeachingProvider>();
    // Subjects and courses feed the "Materia" filter and the
    // create-assignment form; academic periods the period picker.
    context.read<SubjectsProvider>().ensure();
    context.read<CoursesProvider>().ensure();
    context.read<ScheduleProvider>().ensureWeek();
    teaching.ensureAssignments();
    teaching.ensureAllPeriodsLoaded();
    _pickDefaultAcademicPeriod();
  }

  /// Selects the running academic period once, when periods are known.
  Future<void> _pickDefaultAcademicPeriod() async {
    final academicPeriods = context.read<AcademicPeriodsProvider>();
    await academicPeriods.ensure();
    if (!mounted ||
        _academicPeriodPicked ||
        !const {
          ViewStatus.success,
          ViewStatus.empty,
        }.contains(academicPeriods.state.status)) {
      return;
    }
    _academicPeriodPicked = true;
    setState(
      () => _academicPeriodId = defaultAcademicPeriod(academicPeriods.all)?.id,
    );
  }

  // Filtering happens in memory over the whole assignment catalog.
  void _onFiltersChanged(AssignmentFilters filters) =>
      setState(() => _filters = filters);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => TeachingMobileView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        academicPeriodId: _academicPeriodId,
        onAcademicPeriodChanged: (id) => setState(() => _academicPeriodId = id),
        search: _search,
        onSearchChanged: (value) => setState(() => _search = value),
      ),
      desktop: (_) => TeachingDesktopView(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        academicPeriodId: _academicPeriodId,
        onAcademicPeriodChanged: (id) => setState(() => _academicPeriodId = id),
        search: _search,
        onSearchChanged: (value) => setState(() => _search = value),
        selectedAssignmentId: _selectedAssignmentId,
        onSelect: (id) => setState(() => _selectedAssignmentId = id),
      ),
    );
  }
}
