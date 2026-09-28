import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/state/list_state.dart';
import '../../../subjects/presentation/providers/subjects_provider.dart';
import '../desktop/teaching_desktop_view.dart';
import '../mobile/teaching_mobile_view.dart';
import '../providers/teaching_provider.dart';
import '../shared/teaching_actions.dart';

class TeachingPage extends StatefulWidget {
  const TeachingPage({super.key});

  @override
  State<TeachingPage> createState() => _TeachingPageState();
}

class _TeachingPageState extends State<TeachingPage>
    with SingleTickerProviderStateMixin {
  // Tab and filters live here so they survive a mobile <-> desktop switch;
  // whichever view is mounted attaches its TabBar to this controller.
  late final TabController _tabController;
  AssignmentFilters _filters = const AssignmentFilters();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachingProvider>().loadAssignments();
      context.read<TeachingProvider>().loadPeriods();
      // Needed for the "Materia" filter and the create-assignment form —
      // load once up front instead of assuming the user already visited
      // the Subjects page this session.
      final subjects = context.read<SubjectsProvider>();
      if (subjects.state.status == ViewStatus.initial) subjects.load();
    });
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
      ),
      desktop: (_) => TeachingDesktopView(
        tabController: _tabController,
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }
}
