import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The final grade in a ring: the value, "/ max" under it, the ring filled
/// to where the grade falls in the scale.
class GradeRing extends StatelessWidget {
  const GradeRing({
    super.key,
    required this.value,
    required this.maximum,
    required this.fraction,
    this.size = 104,
  });

  /// Already formatted (e.g. "4.78"); "—" without a grade.
  final String value;
  final String maximum;
  final double? fraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: 'Nota $value de $maximum',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: fraction ?? 0,
                strokeWidth: size * 0.09,
                strokeCap: StrokeCap.round,
                color: AppColors.accentBlue,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.23,
                    ),
                  ),
                  Text(
                    '/ $maximum',
                    style: textTheme.bodySmall?.copyWith(fontSize: size * 0.11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
