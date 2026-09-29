import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../activities/presentation/providers/activities_provider.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../exams/presentation/providers/exams_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../desktop/teaching_period_detail_desktop_view.dart';
import '../mobile/teaching_period_detail_mobile_view.dart';
import '../providers/teaching_provider.dart';

/// One class (teaching period): its details, schedule, students and
/// evaluations.
class TeachingPeriodDetailPage extends StatefulWidget {
  const TeachingPeriodDetailPage({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<TeachingPeriodDetailPage> createState() =>
      _TeachingPeriodDetailPageState();
}

class _TeachingPeriodDetailPageState extends State<TeachingPeriodDetailPage>
    with SingleTickerProviderStateMixin {
  // Resumen / Estudiantes / Clases (Horario) / Evaluaciones, on both
  // layouts. Lives here so the open tab survives a layout switch.
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  )..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = widget.teachingPeriodId;
    final teaching = context.read<TeachingProvider>();
    final students = context.read<StudentsProvider>();
    context.read<ScheduleProvider>().loadClassSchedules(id);
    context.read<ExamsProvider>().load(teachingPeriodId: id);
    context.read<ActivitiesProvider>().load(teachingPeriodId: id);
    context.read<AuditProvider>().loadClassLogs(id);
    teaching.loadPeriodSummary(id);
    await teaching.loadPeriodDetail(id);
    final period = teaching.periodDetail.data;
    if (!mounted || period == null || period.id != id) return;
    students.loadGroupRoster(period.groupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => TeachingPeriodDetailMobileView(
        teachingPeriodId: widget.teachingPeriodId,
        tabController: _tabController,
        onRefresh: _load,
      ),
      desktop: (_) => TeachingPeriodDetailDesktopView(
        teachingPeriodId: widget.teachingPeriodId,
        tabController: _tabController,
        onRefresh: _load,
      ),
    );
  }
}
