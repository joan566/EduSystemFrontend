import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/attendance_session_detail_desktop_view.dart';
import '../mobile/attendance_session_detail_mobile_view.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_marking_controller.dart';

/// Fast attendance marking for one session (§55, §99).
class AttendanceSessionDetailPage extends StatefulWidget {
  const AttendanceSessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<AttendanceSessionDetailPage> createState() =>
      _AttendanceSessionDetailPageState();
}

class _AttendanceSessionDetailPageState
    extends State<AttendanceSessionDetailPage> {
  late final _controller = AttendanceMarkingController(widget.sessionId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AttendanceProvider>();
      await provider.loadDetail(widget.sessionId);
      final detail = provider.detailState.data;
      if (detail != null && mounted) _controller.seed(detail.students);
    });
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
        mobile: (_) =>
            AttendanceSessionDetailMobileView(controller: _controller),
        desktop: (_) =>
            AttendanceSessionDetailDesktopView(controller: _controller),
      ),
    );
  }
}
