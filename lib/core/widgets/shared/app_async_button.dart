import 'package:flutter/material.dart';

import 'app_button.dart';

/// [AppButton] for an action that goes to the backend: it shows its own
/// loading state from the tap until [onPressed] completes, so the tap is
/// acknowledged at once and can't be repeated while the request runs.
class AppAsyncButton extends StatefulWidget {
  const AppAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<AppAsyncButton> createState() => _AppAsyncButtonState();
}

class _AppAsyncButtonState extends State<AppAsyncButton> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: widget.label,
      variant: widget.variant,
      icon: widget.icon,
      expand: widget.expand,
      isLoading: _running,
      onPressed: widget.onPressed == null ? null : _run,
    );
  }
}

/// Icon-only counterpart of [AppAsyncButton]: the icon becomes a small
/// spinner while [onPressed] runs.
class AppAsyncIconButton extends StatefulWidget {
  const AppAsyncIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize,
  });

  final IconData icon;
  final Future<void> Function()? onPressed;
  final String? tooltip;
  final double? iconSize;

  @override
  State<AppAsyncIconButton> createState() => _AppAsyncIconButtonState();
}

class _AppAsyncIconButtonState extends State<AppAsyncIconButton> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.iconSize ?? 24;
    return IconButton(
      tooltip: widget.tooltip,
      iconSize: size,
      onPressed: _running || widget.onPressed == null ? null : _run,
      icon: _running
          ? SizedBox.square(
              dimension: size * 0.75,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
    );
  }
}
