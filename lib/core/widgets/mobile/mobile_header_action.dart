import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The square, blue-tinted icon button at the right of a mobile screen's
/// large title (add, import, go to a date...).
class MobileHeaderAction extends StatelessWidget {
  const MobileHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
        fixedSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
    );
  }
}
