import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/desktop/desktop_stat_card.dart';
import '../../../domain/entities/grading_entities.dart';
import '../../shared/category_visuals.dart';
import '../../shared/class_grades.dart';
import '../../shared/grade_distribution_chart.dart';
import '../../shared/grade_labels.dart';

/// "Resumen de la clase" on desktop: a KPI row, then the distribution and
/// the average per component side by side.
class ClassGradesSummaryDesktop extends StatelessWidget {
  const ClassGradesSummaryDesktop({super.key, required this.data});

  final PeriodGradesEntity data;

  @override
  Widget build(BuildContext context) {
    final summary = ClassGradesSummary.from(data);
    final scale = data.scale;
    final hasPassing = data.passingGrade != null;
    final textTheme = Theme.of(context).textTheme;

    final kpis = [
      DesktopStatCard(
        label: 'Promedio de la clase',
        value: periodGradeLabel(summary.average, scale),
        icon: Icons.star_outline_rounded,
        accentColor: AppColors.accentBlue,
      ),
      DesktopStatCard(
        label: 'Con nota',
        value: '${summary.graded} / ${summary.students}',
        icon: Icons.people_alt_outlined,
        accentColor: AppColors.accentPurple,
      ),
      DesktopStatCard(
        label: 'Aprobados',
        value: hasPassing ? '${summary.passing}' : '—',
        icon: Icons.check_circle_outline,
        accentColor: AppColors.success,
      ),
      DesktopStatCard(
        label: 'Reprobados',
        value: hasPassing ? '${summary.failing}' : '—',
        icon: Icons.cancel_outlined,
        accentColor: AppColors.error,
      ),
    ];

    final distribution = DesktopSectionCard(
      icon: Icons.bar_chart_rounded,
      title: 'Distribución de notas',
      subtitle: summary.graded == 0
          ? null
          : 'de ${periodGradeLabel(summary.lowest, scale)} a ${periodGradeLabel(summary.highest, scale)}',
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: summary.graded == 0
            ? Text('Aparecerá cuando haya notas.', style: textTheme.bodySmall)
            : GradeDistributionChart(bins: summary.bins, plotHeight: 180),
      ),
    );

    final components = DesktopSectionCard(
      icon: Icons.donut_small_outlined,
      title: 'Promedio por componente',
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final c in summary.categories)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    categoryVisuals(c.name).icon,
                    size: 20,
                    color: categoryVisuals(c.name).color,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: Text(
                      '${categoryLabel(c.name)}  ·  ${compactNumber(c.weight)}%',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: c.average == null
                            ? 0
                            : scaleFraction(c.average!, scale),
                        minHeight: 8,
                        color: categoryVisuals(c.name).color,
                        backgroundColor: categoryVisuals(
                          c.name,
                        ).color.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      periodGradeLabel(c.average, scale),
                      textAlign: TextAlign.end,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return ListView(
          children: [
            Row(
              children: [
                for (final (i, card) in kpis.indexed) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: card),
                ],
              ],
            ),
            if (!hasPassing)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Define una nota mínima en Configuración de notas para ver aprobados y reprobados.',
                  style: textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 20),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: distribution),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: components),
                  ],
                ),
              )
            else ...[
              distribution,
              const SizedBox(height: 20),
              components,
            ],
          ],
        );
      },
    );
  }
}
