import 'package:flutter/widgets.dart';

/// Layout family derived from available width. This is the single source of
/// truth for breakpoints — do not hardcode width thresholds elsewhere.
///
/// Mobile and desktop are separate products, not one UI that stretches:
/// each page ships a `mobile/` and a `desktop/` implementation and the page
/// entry point picks one with [ResponsiveBuilder]. Widgets below that point
/// never ask "am I on mobile?" — they already know, by living in the
/// `mobile/` or `desktop/` folder. That's why there is intentionally no
/// `context.isMobile` getter here.
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

/// The one place a widget tree forks into its mobile or desktop
/// implementation. Use it at the page (or shell) entry point only.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final WidgetBuilder mobile;

  /// Falls back to [desktop] when omitted: tablet belongs to the desktop
  /// family unless a module has a real reason to diverge.
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    final type = Breakpoints.deviceTypeOf(MediaQuery.sizeOf(context).width);
    return switch (type) {
      DeviceType.mobile => mobile(context),
      DeviceType.tablet => (tablet ?? desktop)(context),
      DeviceType.desktop => desktop(context),
    };
  }
}
