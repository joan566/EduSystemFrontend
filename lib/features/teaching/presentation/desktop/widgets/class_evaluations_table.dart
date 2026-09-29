import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../shared/class_evaluations.dart';
import 'class_evaluation_lists.dart';

/// "Evaluaciones": every exam and activity of the class in one table.
class ClassEvaluationsTable extends StatelessWidget {
  const ClassEvaluationsTable({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    final result = watchClassEvaluations(context, teachingPeriodId);
    final items = result.items;
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Evaluaciones',
      subtitle: items == null ? null : '${items.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppButton(
                label: 'Crear examen',
                icon: Icons.add,
                onPressed: () => context.push(
                  RoutePaths.examCreateForClass(teachingPeriodId),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Nueva actividad',
                icon: Icons.add,
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(
                  RoutePaths.activitiesForClass(teachingPeriodId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.failed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'No pudimos cargar las evaluaciones.',
                    style: textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: result.retry,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else if (items == null)
            const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (items.isEmpty)
            const AppEmptyState(
              title: 'Sin evaluaciones',
              message: 'Crea un examen o una actividad para empezar a evaluar.',
              icon: Icons.fact_check_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingTextStyle: textTheme.labelMedium,
                    columns: const [
                      DataColumn(label: Text('TIPO')),
                      DataColumn(label: Text('NOMBRE')),
                      DataColumn(label: Text('FECHA')),
                      DataColumn(label: Text('DETALLE')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => context.push(item.route),
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TintedIcon(
                                    icon: item.kind == ClassEvaluationKind.exam
                                        ? Icons.fact_check_outlined
                                        : Icons.assignment_outlined,
                                    color: item.kind == ClassEvaluationKind.exam
                                        ? AppColors.accentBlue
                                        : AppColors.accentPurple,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item.kindLabel),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                item.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                item.date == null
                                    ? '—'
                                    : Formatters.date(item.date!),
                              ),
                            ),
                            DataCell(Text(item.detail)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
