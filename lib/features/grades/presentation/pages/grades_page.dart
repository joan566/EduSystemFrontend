import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/class_picker.dart';
import '../desktop/grades_desktop_view.dart';
import '../mobile/grades_mobile_view.dart';
import '../providers/grading_provider.dart';
import '../shared/class_grades.dart';

/// "Calificaciones": a class's students with their period grade, and the
/// class summary. Weights live apart, in Configuración de notas.
class GradesPage extends StatefulWidget {
  const GradesPage({super.key, this.initialTeachingPeriodId});

  /// Class to preselect (from `?teachingPeriodId=`), e.g. when opened from
  /// a class screen.
  final int? initialTeachingPeriodId;

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage>
    with SyncedDataState<GradesPage> {
  // Live here so they survive a mobile <-> desktop switch.
  TeachingPeriodEntity? _period;
  int _tab = 0;
  GradesListFilters _filters = const GradesListFilters();
  int? _selectedStudentId;

  /// The class's grades come from memory unless a grade, weight or
  /// evaluation of it changed (e.g. inside a student's report).
  @override
  void ensureData() {
    final period = _period;
    if (period != null) {
      context.read<GradingProvider>().ensurePeriodGrades(period.id);
    } else {
      _pickInitialClass();
    }
  }

  Future<void> _pickInitialClass() async {
    final period = await initialClass(
      context,
      preferredId: widget.initialTeachingPeriodId,
    );
    if (!mounted || _period != null) return;
    _onPeriodChanged(period);
  }

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    if (period == null || period.id == _period?.id) return;
    setState(() {
      _period = period;
      _selectedStudentId = null;
    });
    context.read<GradingProvider>().ensurePeriodGrades(period.id);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => GradesMobileView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
        filters: _filters,
        onFiltersChanged: (f) => setState(() => _filters = f),
      ),
      desktop: (_) => GradesDesktopView(
        period: _period,
        onPeriodChanged: _onPeriodChanged,
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
        filters: _filters,
        onFiltersChanged: (f) => setState(() => _filters = f),
        selectedStudentId: _selectedStudentId,
        onSelect: (id) => setState(() => _selectedStudentId = id),
      ),
    );
  }
}
