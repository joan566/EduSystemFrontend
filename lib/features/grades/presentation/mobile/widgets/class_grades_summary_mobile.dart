import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/mobile/mobile_section_card.dart';
import '../../../domain/entities/grading_entities.dart';
import '../../shared/category_visuals.dart';
import '../../shared/class_grades.dart';
import '../../shared/grade_distribution_chart.dart';
import '../../shared/grade_labels.dart';

/// "Resumen de la clase": key figures, how grades are distributed and the
/// class average per component.
class ClassGradesSummaryMobile extends StatelessWidget {
  const ClassGradesSummaryMobile({super.key, required this.data});

  final PeriodGradesEntity data;

  @override
  Widget build(BuildContext context) {
    final summary = ClassGradesSummary.from(data);
    final scale = data.scale;
    final hasPassing = data.passingGrade != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _Figure(
              icon: Icons.star_outline_rounded,
              color: AppColors.accentBlue,
              value: periodGradeLabel(summary.average, scale),
              label: 'Promedio',
            ),
            _Figure(
              icon: Icons.people_alt_outlined,
              color: AppColors.accentPurple,
              value: '${summary.graded} / ${summary.students}',
              label: 'Con nota',
            ),
            _Figure(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              value: hasPassing ? '${summary.passing}' : '—',
              label: 'Aprobados',
            ),
            _Figure(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              value: hasPassing ? '${summary.failing}' : '—',
              label: 'Reprobados',
            ),
          ],
        ),
        if (!hasPassing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Define una nota mínima en Configuración de notas para ver '
              'aprobados y reprobados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        MobileSectionCard(
          icon: Icons.bar_chart_rounded,
          title: 'Distribución de notas',
          subtitle: summary.graded == 0
              ? null
              : 'de ${periodGradeLabel(summary.lowest, scale)} a '
                    '${periodGradeLabel(summary.highest, scale)}',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: summary.graded == 0
                ? Text(
                    'Aparecerá cuando haya notas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : GradeDistributionChart(bins: summary.bins),
          ),
        ),
        const SizedBox(height: 16),
        MobileSectionCard(
          icon: Icons.donut_small_outlined,
          title: 'Promedio por componente',
          child: Column(
            children: [
              const SizedBox(height: 8),
              for (final c in summary.categories)
                _CategoryRow(category: c, scale: scale),
            ],
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(label, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.scale});

  final CategoryAverage category;
  final GradingScaleEntity scale;

  @override
  Widget build(BuildContext context) {
    final visuals = categoryVisuals(category.name);
    final textTheme = Theme.of(context).textTheme;
    final average = category.average;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(visuals.icon, size: 18, color: visuals.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${visuals.label}  ·  ${compactNumber(category.weight)}%',
                  style: textTheme.bodyMedium,
                ),
              ),
              Text(
                periodGradeLabel(average, scale),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: average == null ? 0 : scaleFraction(average, scale),
              minHeight: 6,
              color: visuals.color,
              backgroundColor: visuals.color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
