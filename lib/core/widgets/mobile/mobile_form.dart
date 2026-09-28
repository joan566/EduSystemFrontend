import 'package:flutter/material.dart';

import '../shared/app_form_frame.dart';

/// Pushes [child] as a full-screen route. Any [AppFormFrame] inside renders
/// as [MobileFormScaffold]: app bar with close, scrollable body, actions
/// pinned above the keyboard/home indicator.
Future<T?> showMobileForm<T>(BuildContext context, {required Widget child}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AppFormFrameScope(
        builder: (context, frame) => MobileFormScaffold(
          title: frame.title,
          actions: frame.actions,
          child: frame.child,
        ),
        child: child,
      ),
    ),
  );
}

/// Shows [builder]'s content in a modal bottom sheet — for short, light
/// choices. Any [AppFormFrame] inside renders as [MobileSheetFrame].
Future<T?> showMobileSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => AppFormFrameScope(
      builder: (context, frame) => MobileSheetFrame(
        title: frame.title,
        actions: frame.actions,
        child: frame.child,
      ),
      child: Builder(builder: builder),
    ),
  );
}

class MobileFormScaffold extends StatelessWidget {
  const MobileFormScaffold({
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: child,
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class MobileSheetFrame extends StatelessWidget {
  const MobileSheetFrame({
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
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Flexible(child: SingleChildScrollView(child: child)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
