import 'package:flutter/widgets.dart';

/// Device class derived from available width. This is the single source of
/// truth for responsive breakpoints — do not hardcode width thresholds
/// elsewhere in the app.
enum DeviceType { mobile, tablet, desktop }

/// Centralized breakpoint strategy.
class Breakpoints {
  Breakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static DeviceType deviceTypeOf(double width) {
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Convenience extension to query the current [DeviceType] and helpers
/// from any [BuildContext].
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  DeviceType get deviceType => Breakpoints.deviceTypeOf(screenWidth);

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// True for tablet or desktop — i.e. "not a phone-sized layout".
  bool get isWideScreen => !isMobile;
}

/// Builds a different widget tree per [DeviceType], sharing the same
/// underlying domain/state layer. Prefer this over ad-hoc
/// `MediaQuery.of(context).size.width < 600` checks scattered across
/// widgets.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final WidgetBuilder mobile;

  /// Falls back to [desktop] when omitted (tablet reuses the desktop
  /// layout unless a module has a real reason to diverge).
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    switch (context.deviceType) {
      case DeviceType.mobile:
        return mobile(context);
      case DeviceType.tablet:
        return (tablet ?? desktop)(context);
      case DeviceType.desktop:
        return desktop(context);
    }
  }
}

/// Simple value-per-breakpoint resolver, useful for paddings, column
/// counts, etc. without building a whole separate widget tree.
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  switch (context.deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? desktop;
    case DeviceType.desktop:
      return desktop;
  }
}
