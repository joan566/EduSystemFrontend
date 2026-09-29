import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../domain/entities/academic_period_entity.dart';
import '../../shared/period_timeline.dart';

/// The periods on one time axis (months as ticks, today as a line), so
/// gaps and overlaps between them are visible at a glance.
class PeriodTimelineCard extends StatelessWidget {
  const PeriodTimelineCard({super.key, required this.periods});

  final List<AcademicPeriodEntity> periods;

  static const _labelWidth = 150.0;
  static const _rowHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sorted = [...periods]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    // Whole months around the periods, so the axis starts and ends clean.
    final first = sorted.first.startDate;
    final last = sorted
        .map((p) => p.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final from = DateTime(first.year, first.month);
    final to = DateTime(last.year, last.month + 1);
    final span = to.difference(from).inDays.toDouble();
    final today = DateTime.now();
    final months = [
      for (
        var m = DateTime(from.year, from.month);
        m.isBefore(to);
        m = DateTime(m.year, m.month + 1)
      )
        m,
    ];

    return DesktopSectionCard(
      icon: Icons.timeline,
      title: 'Línea de tiempo',
      subtitle:
          '${DateFormat('MMM y').format(from)} – ${DateFormat('MMM y').format(to.subtract(const Duration(days: 1)))}',
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - _labelWidth;
            double x(DateTime d) =>
                (d.difference(from).inDays / span * width).clamp(0, width);
            final showToday = !today.isBefore(from) && today.isBefore(to);

            return SizedBox(
              height: sorted.length * _rowHeight + 26,
              child: Stack(
                children: [
                  // Month gridlines and labels: hairline, recessive.
                  for (final m in months)
                    Positioned(
                      left: _labelWidth + x(m),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: colors.outline.withValues(alpha: 0.6),
                      ),
                    ),
                  for (final m in months)
                    Positioned(
                      left: _labelWidth + x(m) + 4,
                      bottom: 0,
                      child: Text(
                        monthShort(m),
                        style: textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  for (final (i, p) in sorted.indexed) ...[
                    Positioned(
                      left: 0,
                      top: i * _rowHeight + 6,
                      width: _labelWidth - 12,
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _labelWidth + x(p.startDate),
                      top: i * _rowHeight + 5,
                      width: (x(p.endDate) - x(p.startDate)).clamp(6, width),
                      height: 18,
                      child: Tooltip(
                        message:
                            '${p.name}: ${periodRange(p)} (${periodWeeks(p)} semanas)',
                        child: Container(
                          decoration: BoxDecoration(
                            color: switch (periodStatus(p)) {
                              PeriodStatus.active => AppColors.success,
                              PeriodStatus.upcoming => AppColors.accentBlue,
                              PeriodStatus.finished => AppColors.primaryLight,
                            },
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showToday) ...[
                    Positioned(
                      left: _labelWidth + x(today) - 1,
                      top: 0,
                      bottom: 16,
                      child: Container(width: 2, color: AppColors.error),
                    ),
                    Positioned(
                      left: _labelWidth + x(today) + 4,
                      top: sorted.length * _rowHeight - 4,
                      child: Text(
                        'Hoy',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
