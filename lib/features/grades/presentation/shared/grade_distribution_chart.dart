import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'class_grades.dart';
import 'grade_labels.dart';

/// Histogram of period grades: one column per range of the scale, the
/// count on its cap and a tooltip with the exact range. A single series
/// in one hue, so no legend: the card's title names it.
class GradeDistributionChart extends StatelessWidget {
  const GradeDistributionChart({
    super.key,
    required this.bins,
    this.plotHeight = 120,
  });

  final List<GradeBin> bins;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final peak = bins.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return Semantics(
      label: [
        for (final b in bins)
          '${b.count} entre ${compactNumber(b.from)} y ${compactNumber(b.to)}',
      ].join(', '),
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: plotHeight + 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bin in bins)
                    Expanded(
                      child: _Column(
                        bin: bin,
                        fraction: peak == 0 ? 0 : bin.count / peak,
                        plotHeight: plotHeight,
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.outline),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final bin in bins)
                  Expanded(
                    child: Text(
                      '${compactNumber(bin.from)}–${compactNumber(bin.to)}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Column extends StatefulWidget {
  const _Column({
    required this.bin,
    required this.fraction,
    required this.plotHeight,
  });

  final GradeBin bin;
  final double fraction;
  final double plotHeight;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bin = widget.bin;
    final height = bin.count == 0
        ? 0.0
        : (widget.plotHeight * widget.fraction).clamp(4.0, widget.plotHeight);
    final students = bin.count == 1
        ? '1 estudiante'
        : '${bin.count} estudiantes';

    // The whole column is the hover/tap target, not just the bar.
    return Tooltip(
      message:
          '$students con nota entre ${compactNumber(bin.from)} y '
          '${compactNumber(bin.to)}',
      triggerMode: TooltipTriggerMode.tap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          color: _hovering
              ? AppColors.accentBlue.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${bin.count}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: _hovering
                      ? AppColors.primaryMedium
                      : AppColors.accentBlue,
                  // Rounded data end, square at the baseline.
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
