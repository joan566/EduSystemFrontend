import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/activity_detail_desktop_view.dart';
import '../mobile/activity_detail_mobile_view.dart';
import '../providers/activities_provider.dart';
import '../shared/activity_grades_controller.dart';

/// Grade capture for one activity (§99).
class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final int activityId;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final _controller = ActivityGradesController(widget.activityId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ActivitiesProvider>().loadDetail(widget.activityId),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ResponsiveBuilder(
        mobile: (_) => ActivityDetailMobileView(controller: _controller),
        desktop: (_) => ActivityDetailDesktopView(controller: _controller),
      ),
    );
  }
}
