import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/grading_entities.dart';
import '../shared/grading_configuration_cards.dart';
import '../shared/grading_configuration_controller.dart';
import '../shared/grading_scale_form.dart';
import '../shared/period_grades_state_view.dart';

class GradesDesktopView extends StatelessWidget {
  const GradesDesktopView({
    super.key,
    required this.period,
    required this.config,
    required this.onPeriodChanged,
    this.preferredPeriodId,
  });

  final TeachingPeriodEntity? period;
  final GradingConfigurationController? config;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  /// Class the selector picks on first load, if present.
  final int? preferredPeriodId;

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    final config = this.config;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const DesktopPageHeader(
              title: 'Calificaciones',
              subtitle:
                  'Configura la escala, las ponderaciones y consulta las notas del periodo.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TeachingPeriodSelector(
                preferredId: preferredPeriodId,
                value: period,
                onChanged: onPeriodChanged,
              ),
            ),
            const SizedBox(height: 8),
            if (period == null || config == null)
              const Expanded(
                child: AppEmptyState(
                  title: 'Selecciona una clase',
                  message:
                      'Elige una clase arriba para configurar su escala de '
                      'calificación o consultar sus notas.',
                  icon: Icons.grade_outlined,
                ),
              )
            else ...[
              const TabBar(
                tabs: [
                  Tab(text: 'Configuración'),
                  Tab(text: 'Notas del periodo'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ConfigurationTab(controller: config),
                    _PeriodGradesTab(teachingPeriodId: period.id),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desktop: scale and weights side by side.
class _ConfigurationTab extends StatelessWidget {
  const _ConfigurationTab({required this.controller});

  final GradingConfigurationController controller;

  Future<void> _createScale(BuildContext context) async {
    final data = await showDesktopDialog<GradingScaleFormResult>(
      context,
      child: const GradingScaleForm(),
    );
    if (data == null || !context.mounted) return;
    await controller.createScale(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return GradingConfigurationStateView(
      controller: controller,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GradingScaleCard(
                controller: controller,
                onCreateScale: () => _createScale(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: GradingWeightsCard(controller: controller)),
          ],
        ),
      ),
    );
  }
}

class _PeriodGradesTab extends StatelessWidget {
  const _PeriodGradesTab({required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    return PeriodGradesStateView(
      teachingPeriodId: teachingPeriodId,
      builder: (context, data) {
        final categoryNames = data.students.first.categories
            .map((c) => c.categoryName)
            .toList();
        return DesktopDataTable<StudentPeriodGrade>(
          items: data.students,
          columns: [
            DesktopDataColumn(
              label: 'Estudiante',
              cellBuilder: (item) => Text(item.studentName),
            ),
            for (final name in categoryNames)
              DesktopDataColumn(
                label: name,
                cellBuilder: (item) {
                  final category = item.categories.firstWhere(
                    (c) => c.categoryName == name,
                  );
                  return Text(
                    category.achievement != null
                        ? '${category.achievement!.toStringAsFixed(1)}%'
                        : '—',
                  );
                },
              ),
            DesktopDataColumn(
              label: 'Nota del periodo',
              cellBuilder: (item) => Text(
                item.periodGrade != null
                    ? Formatters.grade(
                        item.periodGrade!,
                        data.scale.maximumValue,
                      )
                    : '—',
              ),
            ),
          ],
        );
      },
    );
  }
}
