import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _StudentGradesPageState extends State<StudentGradesPage> {
  // Mobile's tab (Detalle de notas / Información); lives here so it
  // survives a layout switch.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => context.read<GradebookProvider>().loadReport(
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
        onRefresh: _load,
      ),
      desktop: (_) => StudentGradesDesktopView(
        teachingPeriodId: widget.teachingPeriodId,
        studentId: widget.studentId,
        onRefresh: _load,
      ),
    );
  }
}
