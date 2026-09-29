import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../shared/exam_results_summary.dart';

/// Histogram of final grades: one column per grade range, the count on
/// its cap and a tooltip with the exact range. A single series in one hue,
/// so no legend: the card's title names it.
class GradeDistributionChart extends StatelessWidget {
  const GradeDistributionChart({super.key, required this.bins});

  final List<GradeBin> bins;

  static const _plotHeight = 140.0;
  static const _barWidth = 24.0;

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final peak = bins.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return Semantics(
      label: [
        for (final b in bins) '${b.count} entre ${_n(b.from)} y ${_n(b.to)}',
      ].join(', '),
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: _plotHeight + 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bin in bins)
                    Expanded(
                      child: _Column(
                        bin: bin,
                        fraction: peak == 0 ? 0 : bin.count / peak,
                        plotHeight: _plotHeight,
                        barWidth: _barWidth,
                        label: _n,
                      ),
                    ),
                ],
              ),
            ),
            // Baseline: one hairline, recessive.
            Divider(height: 1, thickness: 1, color: colors.outline),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final bin in bins)
                  Expanded(
                    child: Text(
                      '${_n(bin.from)}–${_n(bin.to)}',
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
    required this.barWidth,
    required this.label,
  });

  final GradeBin bin;
  final double fraction;
  final double plotHeight;
  final double barWidth;
  final String Function(double) label;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bin = widget.bin;
    final height = bin.count == 0
        ? 0.0
        : (widget.plotHeight * widget.fraction).clamp(4.0, widget.plotHeight);
    final students = bin.count == 1
        ? '1 estudiante'
        : '${bin.count} estudiantes';

    // The whole column is the hover target, not just the bar.
    return Tooltip(
      message:
          '$students con nota entre ${widget.label(bin.from)} y '
          '${widget.label(bin.to)}',
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
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: widget.barWidth,
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
