import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Root of a skeleton (loading placeholder) tree.
///
/// Every [SkeletonBox] below it shares one shimmer: a single controller
/// drives a soft highlight that sweeps across the whole skeleton at once,
/// the way the real content would appear, instead of each bone pulsing on
/// its own. Bones only repaint (never rebuild) per frame, inside one
/// repaint boundary.
///
/// The skeleton stays invisible for [delay] and then fades in, so a request
/// that answers almost at once shows the content directly instead of
/// flashing a skeleton for a few frames. No minimum display time is
/// imposed: real data always replaces it as soon as it arrives.
///
/// Use it for content that is being read from the backend; an action in
/// progress (saving, deleting) keeps its inline indicator.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 150),
  });

  final Widget child;
  final Duration delay;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with TickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 220);

  final _anchor = GlobalKey();
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: widget.delay + _fade,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _reveal,
    curve: Interval(
      widget.delay.inMicroseconds / (widget.delay + _fade).inMicroseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _shimmer.stop();
      _reveal.value = 1;
    } else {
      if (!_shimmer.isAnimating) _shimmer.repeat();
      if (_reveal.isDismissed) _reveal.forward();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final base = isDark
        ? colors.surfaceContainerHighest
        : Color.lerp(colors.surfaceContainerHighest, colors.outline, 0.45)!;
    final highlight = isDark
        ? Color.lerp(base, colors.onSurface, 0.07)!
        : Color.lerp(base, colors.surface, 0.65)!;

    return Semantics(
      label: 'Cargando contenido',
      container: true,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            key: _anchor,
            child: FadeTransition(
              opacity: _opacity,
              child: _SkeletonScope(
                anchor: _anchor,
                shimmer: _shimmer,
                base: base,
                highlight: highlight,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({
    required this.anchor,
    required this.shimmer,
    required this.base,
    required this.highlight,
    required super.child,
  });

  final GlobalKey anchor;
  final Animation<double> shimmer;
  final Color base;
  final Color highlight;

  static _SkeletonScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();

  @override
  bool updateShouldNotify(_SkeletonScope old) =>
      anchor != old.anchor ||
      shimmer != old.shimmer ||
      base != old.base ||
      highlight != old.highlight;
}

/// A rectangular bone: the building block every other skeleton piece is
/// made of. Without a [width] it takes the available (bounded) width.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 6})
    : _circle = false;

  /// A circular bone (avatar, round icon, ring).
  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      _circle = true;

  final double? width;
  final double height;
  final double radius;
  final bool _circle;

  @override
  Widget build(BuildContext context) {
    final scope = _SkeletonScope.maybeOf(context);
    final fallback = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: width,
      height: height,
      child: _Bone(
        radius: radius,
        circle: _circle,
        anchor: scope?.anchor,
        shimmer: scope?.shimmer,
        base: scope?.base ?? fallback,
        highlight: scope?.highlight ?? fallback,
      ),
    );
  }
}

/// A circular bone of [size].
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SkeletonBox.circle(size: size);
}

/// One or more lines of text-shaped bones sized from [style] (defaults to
/// `bodyMedium`), so a placeholder takes the room its text will take.
///
/// The last line of a paragraph is shorter, like real text.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.style,
    this.width,
    this.widthFactor,
    this.lines = 1,
    this.lastLineFactor = 0.6,
  });

  final TextStyle? style;

  /// Fixed width of each line; otherwise [widthFactor] of the available
  /// width (full width when both are null).
  final double? width;
  final double? widthFactor;
  final int lines;
  final double lastLineFactor;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? Theme.of(context).textTheme.bodyMedium;
    final fontSize = resolved?.fontSize ?? 14;
    final lineHeight = fontSize * (resolved?.height ?? 1.3);
    final boneHeight = (fontSize * 0.78).roundToDouble();

    Widget line(double factor) {
      final bone = SkeletonBox(
        width: width == null ? null : width! * factor,
        height: boneHeight,
        radius: boneHeight / 2.6,
      );
      return SizedBox(
        height: lineHeight,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: width != null || (widthFactor ?? 1) * factor >= 1
              ? bone
              : FractionallySizedBox(
                  widthFactor: (widthFactor ?? 1) * factor,
                  child: bone,
                ),
        ),
      );
    }

    if (lines == 1) return line(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines; i++)
          line(i == lines - 1 ? lastLineFactor : 1),
      ],
    );
  }
}

class _Bone extends LeafRenderObjectWidget {
  const _Bone({
    required this.radius,
    required this.circle,
    required this.anchor,
    required this.shimmer,
    required this.base,
    required this.highlight,
  });

  final double radius;
  final bool circle;
  final GlobalKey? anchor;
  final Animation<double>? shimmer;
  final Color base;
  final Color highlight;

  @override
  _RenderBone createRenderObject(BuildContext context) => _RenderBone(
    radius: radius,
    circle: circle,
    anchor: anchor,
    shimmer: shimmer,
    base: base,
    highlight: highlight,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderBone renderObject) {
    renderObject
      ..radius = radius
      ..circle = circle
      ..anchor = anchor
      ..shimmer = shimmer
      ..base = base
      ..highlight = highlight;
  }
}

class _RenderBone extends RenderBox {
  _RenderBone({
    required double radius,
    required bool circle,
    required this.anchor,
    required Animation<double>? shimmer,
    required Color base,
    required Color highlight,
  }) : _radius = radius,
       _circle = circle,
       _shimmer = shimmer,
       _base = base,
       _highlight = highlight;

  GlobalKey? anchor;

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  bool _circle;
  set circle(bool value) {
    if (value == _circle) return;
    _circle = value;
    markNeedsPaint();
  }

  Color _base;
  set base(Color value) {
    if (value == _base) return;
    _base = value;
    markNeedsPaint();
  }

  Color _highlight;
  set highlight(Color value) {
    if (value == _highlight) return;
    _highlight = value;
    markNeedsPaint();
  }

  Animation<double>? _shimmer;
  set shimmer(Animation<double>? value) {
    if (value == _shimmer) return;
    if (attached) _shimmer?.removeListener(markNeedsPaint);
    _shimmer = value;
    if (attached) _shimmer?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _shimmer?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _shimmer?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.hasBoundedWidth ? constraints.biggest : constraints.smallest;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    final paint = Paint()..color = _base;
    final shimmer = _shimmer;
    final scope = anchor?.currentContext?.findRenderObject();
    if (shimmer != null && scope is RenderBox && scope.hasSize) {
      // The gradient spans the whole skeleton, so every bone shows its own
      // slice of one highlight sweeping across it.
      final origin = localToGlobal(Offset.zero, ancestor: scope);
      final bounds = (offset - origin) & scope.size;
      paint.shader = LinearGradient(
        begin: const Alignment(-1, -0.4),
        end: const Alignment(1, 0.4),
        colors: [_base, _highlight, _base],
        stops: const [0.38, 0.5, 0.62],
        transform: _Slide(
          -1.2 + 2.4 * Curves.easeInOut.transform(shimmer.value),
        ),
      ).createShader(bounds);
    }
    final rect = offset & size;
    if (_circle) {
      context.canvas.drawOval(rect, paint);
    } else {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(_radius)),
        paint,
      );
    }
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}
