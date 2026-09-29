import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../shared/grading_configuration_cards.dart';
import '../shared/grading_configuration_controller.dart';
import '../shared/grading_scale_form.dart';
import '../shared/period_grades_state_view.dart';

class GradesMobileView extends StatelessWidget {
  const GradesMobileView({
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
            const MobilePageHeader(title: 'Calificaciones'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  Tab(text: 'Notas'),
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

class _ConfigurationTab extends StatelessWidget {
  const _ConfigurationTab({required this.controller});

  final GradingConfigurationController controller;

  Future<void> _createScale(BuildContext context) async {
    final data = await showMobileForm<GradingScaleFormResult>(
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
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradingScaleCard(
            controller: controller,
            onCreateScale: () => _createScale(context),
          ),
          const SizedBox(height: 12),
          GradingWeightsCard(controller: controller),
        ],
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
      builder: (context, data) => MobileCardList(
        items: data.students,
        itemBuilder: (context, item) => AppListTile(
          icon: Icons.grade_outlined,
          title: item.studentName,
          subtitle: item.categories
              .map(
                (c) =>
                    '${c.categoryName}: ${c.achievement?.toStringAsFixed(1) ?? '—'}',
              )
              .join(' · '),
          subtitleMaxLines: 2,
          trailing: Text(
            item.periodGrade != null
                ? Formatters.grade(item.periodGrade!, data.scale.maximumValue)
                : '—',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
