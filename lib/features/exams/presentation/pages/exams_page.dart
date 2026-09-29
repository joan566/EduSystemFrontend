import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/exams_desktop_view.dart';
import '../mobile/exams_mobile_view.dart';
import '../providers/exams_provider.dart';
import '../shared/exam_list_filters.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  // Live here so the selected class and the list filters survive a
  // mobile <-> desktop switch.
  TeachingPeriodEntity? _period;
  ExamListFilters _filters = const ExamListFilters();

  /// Exam highlighted in the desktop table / preview pane.
  int? _selectedExamId;

  @override
  void initState() {
    super.initState();
    // Neither layout's class picker loads classes itself: the first class
    // is selected here.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final teaching = context.read<TeachingProvider>();
      await teaching.ensureAllPeriodsLoaded();
      if (!mounted || _period != null || teaching.allPeriods.isEmpty) return;
      _onPeriodChanged(teaching.allPeriods.first);
    });
  }

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    if (period?.id == _period?.id) return;
    setState(() {
      _period = period;
      _selectedExamId = null;
    });
    if (period != null) {
      context.read<ExamsProvider>().load(teachingPeriodId: period.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => ExamsMobileView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        filters: _filters,
        onFiltersChanged: (filters) => setState(() => _filters = filters),
      ),
      desktop: (_) => ExamsDesktopView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        filters: _filters,
        onFiltersChanged: (filters) => setState(() => _filters = filters),
        selectedExamId: _selectedExamId,
        onSelect: (id) => setState(() => _selectedExamId = id),
      ),
    );
  }
}
