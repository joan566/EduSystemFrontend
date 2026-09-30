import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
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
    with
        SingleTickerProviderStateMixin,
        SyncedDataState<TeachingPeriodDetailPage> {
  // Resumen / Estudiantes / Clases (Horario) / Evaluaciones, on both
  // layouts. Lives here so the open tab survives a layout switch.
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  )..addListener(() => setState(() {}));

  /// Everything the class screen shows. What is already cached for this
  /// class (from an earlier visit or another screen) is not read again;
  /// what a mutation made stale is.
  @override
  void ensureData() {
    final id = widget.teachingPeriodId;
    context.read<ScheduleProvider>().ensureClassSchedules(id);
    context.read<ExamsProvider>().ensureExams(id);
    context.read<ActivitiesProvider>().ensureActivities(id);
    context.read<AuditProvider>().ensureClassLogs(id);
    final teaching = context.read<TeachingProvider>();
    teaching.ensurePeriodSummary(id);
    teaching.ensurePeriodDetail(id).then((_) {
      final period = teaching.periodDetail(id).data;
      if (!mounted || period == null) return;
      context.read<StudentsProvider>().ensureGroupRoster(period.groupId);
    });
  }

  /// Pull-to-refresh / "Actualizar": re-reads everything shown.
  Future<void> _refresh() async {
    final id = widget.teachingPeriodId;
    final teaching = context.read<TeachingProvider>();
    final students = context.read<StudentsProvider>();
    await Future.wait([
      context.read<ScheduleProvider>().refreshClassSchedules(id),
      context.read<ExamsProvider>().refreshExams(id),
      context.read<ActivitiesProvider>().refreshActivities(id),
      context.read<AuditProvider>().refreshClassLogs(id),
      teaching.refreshPeriodSummary(id),
      teaching.refreshPeriodDetail(id),
    ]);
    final period = teaching.periodDetail(id).data;
    if (period != null) await students.refreshGroupRoster(period.groupId);
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
        onRefresh: _refresh,
      ),
      desktop: (_) => TeachingPeriodDetailDesktopView(
        teachingPeriodId: widget.teachingPeriodId,
        tabController: _tabController,
        onRefresh: _refresh,
      ),
    );
  }
}
