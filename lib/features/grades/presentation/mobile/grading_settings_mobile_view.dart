import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/mobile/class_picker_sheet.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/grading_configuration_controller.dart';
import '../shared/grading_configuration_state_view.dart';
import '../shared/grading_scale_form.dart';

/// Mobile "Configuración de notas": class, how much each component weighs
/// (with the evaluations it covers), the running total, then the scale and
/// the passing grade.
class GradingSettingsMobileView extends StatelessWidget {
  const GradingSettingsMobileView({
    super.key,
    required this.period,
    required this.config,
    required this.onPeriodChanged,
  });

  final TeachingPeriodEntity? period;
  final GradingConfigurationController? config;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  Future<void> _openMore(BuildContext context) async {
    final period = this.period;
    final choice = await showMobileSheet<int>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: const Text('Ver notas de la clase'),
              enabled: period != null,
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Nueva escala'),
              enabled: config != null,
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        context.push(RoutePaths.gradesForClass(period!.id));
      case 1:
        await _createScale(context);
    }
  }

  Future<void> _createScale(BuildContext context) async {
    final data = await showMobileForm<GradingScaleFormResult>(
      context,
      child: const GradingScaleForm(),
    );
    if (data == null || !context.mounted) return;
    await config!.createScale(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final config = this.config;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop())
                  const BackButton()
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de notas',
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Configura los pesos de evaluación para esta clase',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Más opciones',
                  onPressed: () => _openMore(context),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: MobileClassPickerCard(
              value: period,
              onChanged: onPeriodChanged,
              showLabel: true,
            ),
          ),
          Expanded(
            child: config == null
                ? const AppEmptyState(
                    title: 'Selecciona una clase',
                    message: 'Los pesos se configuran para cada clase.',
                    icon: Icons.tune,
                  )
                : GradingConfigurationStateView(
                    controller: config,
                    placeholder: const _EditorSkeleton(),
                    builder: (context) => _Editor(
                      controller: config,
                      onCreateScale: () => _createScale(context),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder of [_Editor]: the weights total card and the components.
class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: SkeletonFill(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonSurface(
              radius: 14,
              padding: EdgeInsets.all(14),
              child: SkeletonTile(leadingSize: 60, gap: 14),
            ),
            SizedBox(height: 14),
            MobileSectionSkeleton(rows: 4, trailingWidth: 56),
            SizedBox(height: 14),
            MobileSectionSkeleton(rows: 2),
          ],
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.controller, required this.onCreateScale});

  final GradingConfigurationController controller;
  final VoidCallback onCreateScale;

  @override
  Widget build(BuildContext context) {
    final grading = context.watch<GradingProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: AppColors.accentBlue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distribución de pesos', style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'La suma de todos los porcentajes debe ser igual al 100%. '
                      'Dentro de un componente, cada evaluación pesa según su '
                      'puntaje máximo.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Componentes de evaluación', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final category in grading.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ComponentTile(category: category, controller: controller),
          ),
        _TotalCard(total: controller.totalWeight),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Escala y aprobación',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: onCreateScale,
                    child: const Text('Nueva escala'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppDropdown<int>(
                label: 'Escala de calificación',
                value: controller.scaleId,
                items: [for (final s in grading.scales) s.id],
                itemLabel: (id) => _scaleLabel(grading.scales, id),
                onChanged: controller.selectScale,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: controller.passingGradeController,
                label: 'Nota mínima para aprobar (opcional)',
                helperText:
                    controller.passingGradeError(grading.scales) ??
                    'Con ella se muestra Aprobado o Reprobado.',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => controller.changed(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Guardar configuración',
          icon: Icons.save_outlined,
          isLoading: controller.saving,
          expand: true,
          onPressed: () => controller.save(context),
        ),
      ],
    );
  }
}

String _scaleLabel(List<GradingScaleEntity> scales, int id) {
  final scale = scales.where((s) => s.id == id).firstOrNull;
  if (scale == null) return 'Escala';
  return '${scale.name} (${compactNumber(scale.minimumValue)}–'
      '${compactNumber(scale.maximumValue)})';
}

class _ComponentTile extends StatefulWidget {
  const _ComponentTile({required this.category, required this.controller});

  final EvaluationCategoryEntity category;
  final GradingConfigurationController controller;

  @override
  State<_ComponentTile> createState() => _ComponentTileState();
}

class _ComponentTileState extends State<_ComponentTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final visuals = categoryVisuals(
      category.name,
      description: category.description,
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final evaluations = widget.controller.evaluationsByCategory?[category.id];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                TintedIcon(icon: visuals.icon, color: visuals.color, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visuals.label, style: textTheme.titleSmall),
                      Text(
                        visuals.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller:
                        widget.controller.weightControllers[category.id],
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: textTheme.titleMedium,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      suffixText: '%',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => widget.controller.changed(),
                  ),
                ),
                IconButton(
                  tooltip: _expanded
                      ? 'Ocultar evaluaciones'
                      : 'Ver evaluaciones',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: evaluations == null
                  ? Text(
                      widget.controller.evaluationsByCategory == null
                          ? 'Cargando evaluaciones...'
                          : 'Sin evaluaciones todavía en esta clase.',
                      style: textTheme.bodySmall,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${evaluations.length} evaluaciones · el peso se reparte '
                          'según el puntaje máximo',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        for (final e in evaluations)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  [
                                    if (e.evaluationDate != null)
                                      Formatters.date(e.evaluationDate!),
                                    'máx. ${compactNumber(e.maximumScore)}',
                                  ].join('  ·  '),
                                  style: textTheme.bodySmall,
                                ),
                              ],
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = weightsTotalStatus(total);
    final color = status.valid ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (total / 100).clamp(0.0, 1.0),
                    strokeWidth: 6,
                    color: status.valid
                        ? AppColors.accentBlue
                        : AppColors.warning,
                    backgroundColor: AppColors.accentBlue.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                Text(
                  '${compactNumber(total)}%',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: textTheme.bodySmall),
                Text(
                  '${compactNumber(total)}%',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.valid
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.valid ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: textTheme.labelMedium?.copyWith(color: color),
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
