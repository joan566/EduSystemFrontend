import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../../academic_periods/presentation/providers/academic_periods_provider.dart';
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
    with SingleTickerProviderStateMixin {
  // Tab, filters, period and search live here so they survive a
  // mobile <-> desktop switch; whichever view is mounted attaches its
  // TabBar to this controller.
  late final TabController _tabController;
  AssignmentFilters _filters = const AssignmentFilters();

  /// Academic period the mobile list shows classes for; null = all.
  int? _academicPeriodId;
  String _search = '';

  /// Row selected in the desktop table (its preview shows beside it).
  int? _selectedAssignmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final teaching = context.read<TeachingProvider>();
    final schedule = context.read<ScheduleProvider>();
    final academicPeriods = context.read<AcademicPeriodsProvider>();
    // Needed for the "Materia" filter and the create-assignment form —
    // load once up front instead of assuming the user already visited
    // the Subjects page this session.
    final subjects = context.read<SubjectsProvider>();
    if (subjects.state.status == ViewStatus.initial) subjects.load();
    if (schedule.week.status == DetailStatus.initial) schedule.loadWeek();
    teaching.loadAssignments();
    teaching.loadPeriods();
    teaching.ensureAllPeriodsLoaded(forceReload: true);

    if (academicPeriods.state.status == ViewStatus.initial) {
      await academicPeriods.load();
    }
    if (!mounted) return;
    setState(
      () => _academicPeriodId = defaultAcademicPeriod(
        academicPeriods.state.items,
      )?.id,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFiltersChanged(AssignmentFilters filters) {
    setState(() => _filters = filters);
    context.read<TeachingProvider>().loadAssignments(
      page: 0,
      subjectId: filters.subjectId,
      active: filters.active,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => TeachingMobileView(
        tabController: _tabController,
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
