import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../desktop/grade_detail_desktop_view.dart';
import '../mobile/grade_detail_mobile_view.dart';
import '../providers/gradebook_provider.dart';

/// A student's grade in one evaluation: weight and contribution,
/// description, rubric, attachment and the teacher's comment.
class GradeDetailPage extends StatefulWidget {
  const GradeDetailPage({
    super.key,
    required this.teachingPeriodId,
    required this.studentId,
    required this.evaluationId,
  });

  final int teachingPeriodId;
  final int studentId;
  final int evaluationId;

  @override
  State<GradeDetailPage> createState() => _GradeDetailPageState();
}

class _GradeDetailPageState extends State<GradeDetailPage>
    with SyncedDataState<GradeDetailPage> {
  @override
  void ensureData() => context.read<GradebookProvider>().ensureDetail(
    widget.evaluationId,
    widget.studentId,
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => GradeDetailMobileView(
        evaluationId: widget.evaluationId,
        studentId: widget.studentId,
      ),
      desktop: (_) => GradeDetailDesktopView(
        evaluationId: widget.evaluationId,
        studentId: widget.studentId,
      ),
    );
  }
}
