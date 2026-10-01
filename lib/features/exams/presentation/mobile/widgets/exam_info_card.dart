import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../domain/entities/exam_entity.dart';
import 'exam_status_chip.dart';

/// Three facts under the exam's name: class, date and readiness.
class ExamInfoCard extends StatelessWidget {
  const ExamInfoCard({super.key, required this.exam, required this.period});

  final ExamEntity exam;

  /// The exam's class; null until the classes have loaded.
  final TeachingPeriodEntity? period;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final period = this.period;
    final date = exam.evaluationDate;
    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: colors.outline,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _Fact(
                icon: Icons.class_outlined,
                value: Text(
                  period == null ? '—' : period.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                label: 'Clase',
              ),
            ),
            divider,
            Expanded(
              flex: 4,
              child: _Fact(
                icon: Icons.calendar_today_outlined,
                value: Text(
                  date == null ? 'Sin fecha' : Formatters.date(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                label: 'Fecha',
              ),
            ),
            divider,
            Expanded(
              flex: 4,
              child: _Fact(
                value: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ExamStatusChip(ready: exam.ready),
                ),
                label: 'Estado',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label, this.icon});

  final IconData? icon;
  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle.merge(
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  child: value,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
