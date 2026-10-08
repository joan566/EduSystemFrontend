import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/exam_import_desktop_view.dart';
import '../mobile/exam_import_mobile_view.dart';
import '../shared/exam_import_controller.dart';

/// Imports a multiple-choice exam from a .docx document.
class ExamImportPage extends StatefulWidget {
  const ExamImportPage({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<ExamImportPage> createState() => _ExamImportPageState();
}

class _ExamImportPageState extends State<ExamImportPage> {
  late final _controller = ExamImportController(
    teachingPeriodId: widget.teachingPeriodId,
  );

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
        mobile: (_) => ExamImportMobileView(controller: _controller),
        desktop: (_) => ExamImportDesktopView(controller: _controller),
      ),
    );
  }
}
