import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Shows [child] as a centered [Dialog] on desktop/tablet, or as a
/// full-screen route on mobile (§106, §75).
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required Widget child,
  double desktopWidth = 480,
}) {
  if (context.isMobile) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => child,
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktopWidth),
        child: child,
      ),
    ),
  );
}

/// Shows [child] as a [Dialog] on desktop/tablet, or as a draggable
/// [BottomSheet] on mobile — for shorter, lighter-weight content than
/// [showAppDialog] (§106).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double desktopWidth = 480,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktopWidth),
        child: builder(ctx),
      ),
    ),
  );
}

/// Standard scaffold for content shown via [showAppDialog]/[showAppSheet]:
/// a title row plus body, with consistent padding.
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
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
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
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
