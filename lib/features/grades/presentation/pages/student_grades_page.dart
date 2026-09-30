import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/student_grades_desktop_view.dart';
import '../mobile/student_grades_mobile_view.dart';
import '../providers/gradebook_provider.dart';

/// A student's grades in one class, evaluation by evaluation.
class StudentGradesPage extends StatefulWidget {
  const StudentGradesPage({
    super.key,
    required this.teachingPeriodId,
    required this.studentId,
  });

  final int teachingPeriodId;
  final int studentId;

  @override
  State<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends State<StudentGradesPage>
    with SyncedDataState<StudentGradesPage> {
  // Mobile's tab (Detalle de notas / Información); lives here so it
  // survives a layout switch.
  int _tab = 0;

  /// A report already seen (and still valid) comes from memory; editing a
  /// grade inside makes it stale, so coming back re-reads it.
  @override
  void ensureData() => context.read<GradebookProvider>().ensureReport(
    widget.teachingPeriodId,
    widget.studentId,
  );

  Future<void> _refresh() => context.read<GradebookProvider>().refreshReport(
    widget.teachingPeriodId,
    widget.studentId,
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => StudentGradesMobileView(
        teachingPeriodId: widget.teachingPeriodId,
        studentId: widget.studentId,
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
        onRefresh: _refresh,
      ),
      desktop: (_) => StudentGradesDesktopView(
        teachingPeriodId: widget.teachingPeriodId,
        studentId: widget.studentId,
        onRefresh: _refresh,
      ),
    );
  }
}
