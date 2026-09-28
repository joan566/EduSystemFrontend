import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/exam_builder_desktop_view.dart';
import '../mobile/exam_builder_mobile_view.dart';
import '../shared/exam_builder_controller.dart';

/// Create-exam wizard: Información → Preguntas → Revisar on one screen.
class ExamBuilderPage extends StatefulWidget {
  const ExamBuilderPage({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<ExamBuilderPage> createState() => _ExamBuilderPageState();
}

class _ExamBuilderPageState extends State<ExamBuilderPage> {
  late final _controller = ExamBuilderController(
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
        mobile: (_) => ExamBuilderMobileView(controller: _controller),
        desktop: (_) => ExamBuilderDesktopView(controller: _controller),
      ),
    );
  }
}
