import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../grades/presentation/providers/grading_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/student_detail_desktop_view.dart';
import '../mobile/student_detail_mobile_view.dart';
import '../providers/students_provider.dart';
import '../shared/student_grades_controller.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({
    super.key,
    required this.studentId,
    this.initialTab = 0,
  });

  final int studentId;
  final int initialTab;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  // Live here so the tab and the loaded grades survive a layout switch.
  late int _tab = widget.initialTab.clamp(0, 2);
  late final StudentGradesController _grades = StudentGradesController(
    teaching: context.read<TeachingProvider>(),
    grading: context.read<GradingProvider>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<StudentsProvider>().loadDetail(widget.studentId),
    );
  }

  @override
  void dispose() {
    _grades.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => StudentDetailMobileView(
        studentId: widget.studentId,
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
        grades: _grades,
      ),
      desktop: (_) => StudentDetailDesktopView(
        studentId: widget.studentId,
        tab: _tab,
        onTabChanged: (tab) => setState(() => _tab = tab),
        grades: _grades,
      ),
    );
  }
}
