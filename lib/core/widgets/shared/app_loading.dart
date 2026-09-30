import 'package:flutter/material.dart';

/// Determinate/indeterminate progress bar for uploads and long-running
/// processing (§60: never just a spinner for everything).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, this.value, this.label});

  /// Null renders an indeterminate bar.
  final double? value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, minHeight: 6),
        ),
        if (value != null) ...[
          const SizedBox(height: 6),
          Text(
            '${(value! * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Content already on screen while a newer version of it loads (the next
/// page, a new search): [child] stays and a slim bar runs on top, instead
/// of replacing it with a skeleton.
class AppUpdating extends StatelessWidget {
  const AppUpdating({super.key, required this.updating, required this.child});

  final bool updating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: updating ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: updating
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ],
    );
  }
}
