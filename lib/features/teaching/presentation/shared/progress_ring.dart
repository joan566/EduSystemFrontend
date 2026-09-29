import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Circular grading-progress indicator with the percentage in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.percent, this.size = 62});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progreso $percent por ciento',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: (percent / 100).clamp(0, 1).toDouble(),
                strokeWidth: size * 0.1,
                strokeCap: StrokeCap.round,
                color: AppColors.accentBlue,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
              ),
            ),
            ExcludeSemantics(
              child: Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
