import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../desktop/teaching_period_detail_desktop_view.dart';
import '../mobile/teaching_period_detail_mobile_view.dart';
import '../providers/teaching_provider.dart';

/// One class (teaching period): its details and its weekly schedule.
class TeachingPeriodDetailPage extends StatefulWidget {
  const TeachingPeriodDetailPage({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<TeachingPeriodDetailPage> createState() =>
      _TeachingPeriodDetailPageState();
}

class _TeachingPeriodDetailPageState extends State<TeachingPeriodDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeachingProvider>().loadPeriodDetail(
        widget.teachingPeriodId,
      );
      context.read<ScheduleProvider>().loadClassSchedules(
        widget.teachingPeriodId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => TeachingPeriodDetailMobileView(
        teachingPeriodId: widget.teachingPeriodId,
      ),
      desktop: (_) => TeachingPeriodDetailDesktopView(
        teachingPeriodId: widget.teachingPeriodId,
      ),
    );
  }
}
