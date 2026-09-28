import 'package:flutter/material.dart';

/// Renders an [AppFormFrame]'s title, body and actions with platform chrome.
typedef AppFormFrameBuilder =
    Widget Function(BuildContext context, AppFormFrame frame);

/// Injected by the code that *presents* a form (a desktop dialog, a mobile
/// full-screen route, a mobile bottom sheet) so the form itself stays
/// platform-agnostic: it declares what it is (title, fields, actions), the
/// presenter decides what it looks like.
class AppFormFrameScope extends InheritedWidget {
  const AppFormFrameScope({
    super.key,
    required this.builder,
    required super.child,
  });

  final AppFormFrameBuilder builder;

  @override
  bool updateShouldNotify(AppFormFrameScope oldWidget) =>
      builder != oldWidget.builder;
}

/// Title + body + actions of a form or dialog content. Only valid inside
/// content opened via `showDesktopDialog`, `showMobileForm` or
/// `showMobileSheet`, which provide the [AppFormFrameScope].
class AppFormFrame extends StatelessWidget {
  const AppFormFrame({
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
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppFormFrameScope>();
    assert(
      scope != null,
      'AppFormFrame must be opened with showDesktopDialog, showMobileForm '
      'or showMobileSheet.',
    );
    return scope!.builder(context, this);
  }
}
