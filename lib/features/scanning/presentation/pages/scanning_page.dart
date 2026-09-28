import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../desktop/scanning_desktop_view.dart';
import '../mobile/scanning_mobile_view.dart';
import '../shared/scanning_controller.dart';

/// Answer-sheet capture flow (§42-45): camera-first on mobile (capture ->
/// preview -> confirm -> upload -> result), drag & drop / file picker on
/// desktop.
class ScanningPage extends StatefulWidget {
  const ScanningPage({super.key, required this.examId});

  final int examId;

  @override
  State<ScanningPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  late final _controller = ScanningController(widget.examId);

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
        mobile: (_) => ScanningMobileView(controller: _controller),
        desktop: (_) => ScanningDesktopView(controller: _controller),
      ),
    );
  }
}
