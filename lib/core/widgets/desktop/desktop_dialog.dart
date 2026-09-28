import 'package:flutter/material.dart';

import '../shared/app_form_frame.dart';

/// Shows [child] as a centered, width-constrained [Dialog]. Any
/// [AppFormFrame] inside renders as [DesktopDialogFrame].
Future<T?> showDesktopDialog<T>(
  BuildContext context, {
  required Widget child,
  double width = 480,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: AppFormFrameScope(
          builder: (context, frame) => DesktopDialogFrame(
            title: frame.title,
            actions: frame.actions,
            child: frame.child,
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Desktop dialog layout: title row with a close button, scrollable body,
/// right-aligned actions.
class DesktopDialogFrame extends StatelessWidget {
  const DesktopDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(child: SingleChildScrollView(child: child)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
