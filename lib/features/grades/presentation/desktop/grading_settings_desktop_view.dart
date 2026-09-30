import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../core/widgets/shared/tinted_icon.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';
import '../shared/category_visuals.dart';
import '../shared/grade_labels.dart';
import '../shared/grading_configuration_controller.dart';
import '../shared/grading_configuration_state_view.dart';
import '../shared/grading_scale_form.dart';

/// Desktop "Configuración de notas": each component's weight set with a
/// slider or typed exactly (and the evaluations it covers one click away);
/// beside it, the distribution as a stacked bar with the running total,
/// the scale, the passing grade and saving.
class GradingSettingsDesktopView extends StatelessWidget {
  const GradingSettingsDesktopView({
    super.key,
    required this.period,
    required this.config,
    required this.onPeriodChanged,
  });

  final TeachingPeriodEntity? period;
  final GradingConfigurationController? config;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  static const _sideWidth = 380.0;
  static const _sideBesideMinWidth = 1040.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final classes = context.watch<TeachingProvider>().allPeriods;
    final period = this.period;
    final config = this.config;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de notas',
                        style: textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cuánto pesa cada componente en la nota final de la clase, en qué escala '
                        'se califica y con cuánto se aprueba.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 340,
                  child: AppDropdown<TeachingPeriodEntity>(
                    label: 'Clase',
                    value: classes.where((c) => c.id == period?.id).firstOrNull,
                    items: classes,
                    itemLabel: (c) => c.displayName,
                    onChanged: onPeriodChanged,
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Ver notas',
                  icon: Icons.grade_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: period == null
                      ? null
                      : () =>
                            context.push(RoutePaths.gradesForClass(period.id)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: config == null
                  ? const AppEmptyState(
                      title: 'Selecciona una clase',
                      message: 'Los pesos se configuran para cada clase.',
                      icon: Icons.tune,
                    )
                  : GradingConfigurationStateView(
                      controller: config,
                      placeholder: const Skeleton(
                        child: SkeletonFill(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DesktopSectionSkeleton(
                                  rows: 5,
                                  trailingWidth: 90,
                                ),
                              ),
                              SizedBox(width: 24),
                              SizedBox(
                                width: 340,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    DesktopSectionSkeleton(
                                      rows: 1,
                                      leading: SkeletonLeading.circle,
                                      leadingSize: 60,
                                    ),
                                    SizedBox(height: 20),
                                    DesktopSectionSkeleton(rows: 2),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      builder: (context) => LayoutBuilder(
                        builder: (context, constraints) {
                          final components = _ComponentsCard(
                            controller: config,
                          );
                          final side = _SideColumn(controller: config);
                          return ListView(
                            padding: const EdgeInsets.only(bottom: 32),
                            children: [
                              if (constraints.maxWidth >= _sideBesideMinWidth)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: components),
                                    const SizedBox(width: 24),
                                    SizedBox(width: _sideWidth, child: side),
                                  ],
                                )
                              else ...[
                                components,
                                const SizedBox(height: 20),
                                side,
                              ],
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentsCard extends StatelessWidget {
  const _ComponentsCard({required this.controller});

  final GradingConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<GradingProvider>().categories;
    final colors = Theme.of(context).colorScheme;
    return DesktopSectionCard(
      icon: Icons.tune,
      title: 'Componentes de evaluación',
      subtitle: 'deben sumar 100%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Dentro de un componente, cada evaluación pesa según su puntaje máximo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final (i, c) in categories.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.outline),
            _ComponentRow(category: c, controller: controller),
          ],
        ],
      ),
    );
  }
}

class _ComponentRow extends StatefulWidget {
  const _ComponentRow({required this.category, required this.controller});

  final EvaluationCategoryEntity category;
  final GradingConfigurationController controller;

  @override
  State<_ComponentRow> createState() => _ComponentRowState();
}

class _ComponentRowState extends State<_ComponentRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final controller = widget.controller;
    final visuals = categoryVisuals(c.name, description: c.description);
    final textTheme = Theme.of(context).textTheme;
    final weight = controller.weightOf(c.id).clamp(0, 100).toDouble();
    final evaluations = controller.evaluationsByCategory?[c.id];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TintedIcon(icon: visuals.icon, color: visuals.color, size: 44),
              const SizedBox(width: 14),
              SizedBox(
                width: 220,
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
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: visuals.color,
                    thumbColor: visuals.color,
                    inactiveTrackColor: visuals.color.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: weight,
                    max: 100,
                    divisions: 20,
                    label: '${compactNumber(weight)}%',
                    onChanged: (v) => controller.setWeight(c.id, v),
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: controller.weightControllers[c.id],
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
                  onChanged: (_) => controller.changed(),
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
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(58, 8, 48, 0),
              child: evaluations == null
                  ? Text(
                      controller.evaluationsByCategory == null
                          ? 'Cargando evaluaciones...'
                          : 'Sin evaluaciones todavía en esta clase.',
                      style: textTheme.bodySmall,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final e in evaluations)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.name,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  [
                                    if (e.evaluationDate != null)
                                      Formatters.date(e.evaluationDate!),
                                    'máx. ${compactNumber(e.maximumScore)}',
                                    if (weight > 0)
                                      '≈ ${_share(weight, e, evaluations)} de la nota',
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

  /// This evaluation's share of the final grade, before excused absences.
  String _share(
    double weight,
    EvaluationSummaryEntity e,
    List<EvaluationSummaryEntity> all,
  ) {
    final total = all.fold<double>(0, (sum, x) => sum + x.maximumScore);
    return total == 0
        ? '0%'
        : '${compactNumber(weight * e.maximumScore / total)}%';
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.controller});

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
    final grading = context.watch<GradingProvider>();
    final textTheme = Theme.of(context).textTheme;
    final total = controller.totalWeight;
    final status = weightsTotalStatus(total);
    final color = status.valid ? AppColors.success : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionCard(
          icon: Icons.pie_chart_outline,
          title: 'Distribución',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${compactNumber(total)}%',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  Flexible(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
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
                              status.valid
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status.label,
                              style: textTheme.labelMedium?.copyWith(
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StackedBar(
                controller: controller,
                categories: grading.categories,
              ),
              const SizedBox(height: 12),
              for (final c in grading.categories)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: categoryVisuals(c.name).color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryLabel(c.name),
                          style: textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${compactNumber(controller.weightOf(c.id))}%',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopSectionCard(
          icon: Icons.straighten,
          title: 'Escala y aprobación',
          linkLabel: 'Nueva escala',
          onLink: () => _createScale(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              AppDropdown<int>(
                label: 'Escala de calificación',
                value: controller.scaleId,
                items: [for (final s in grading.scales) s.id],
                itemLabel: (id) {
                  final s = grading.scales.where((s) => s.id == id).firstOrNull;
                  return s == null
                      ? 'Escala'
                      : '${s.name} (${compactNumber(s.minimumValue)}–${compactNumber(s.maximumValue)})';
                },
                onChanged: controller.selectScale,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: controller.passingGradeController,
                label: 'Nota mínima para aprobar (opcional)',
                helperText:
                    controller.passingGradeError(grading.scales) ??
                    'Con ella las notas muestran Aprobado o Reprobado.',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => controller.changed(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Guardar configuración',
          icon: Icons.save_outlined,
          isLoading: controller.saving,
          expand: true,
          onPressed: () => controller.save(context),
        ),
        if (controller.dirty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Hay cambios sin guardar.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
      ],
    );
  }
}

/// The weights as one bar split by component (2px gaps between segments),
/// with the unassigned part left empty.
class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.controller, required this.categories});

  final GradingConfigurationController controller;
  final List<EvaluationCategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final segments = [
      for (final c in categories)
        if (controller.weightOf(c.id) > 0) (c, controller.weightOf(c.id)),
    ];
    final total = segments.fold<double>(0, (s, e) => s + e.$2);
    final rest = (100 - total).clamp(0, 100).toDouble();

    return Semantics(
      label: segments
          .map((s) => '${categoryLabel(s.$1.name)} ${compactNumber(s.$2)}%')
          .join(', '),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 14,
          child: Row(
            children: [
              for (final (i, s) in segments.indexed) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: (s.$2 * 10).round().clamp(1, 100000),
                  child: Tooltip(
                    message:
                        '${categoryLabel(s.$1.name)}: ${compactNumber(s.$2)}%',
                    child: Container(color: categoryVisuals(s.$1.name).color),
                  ),
                ),
              ],
              if (rest > 0) ...[
                if (segments.isNotEmpty) const SizedBox(width: 2),
                Expanded(
                  flex: (rest * 10).round(),
                  child: Container(color: colors.surfaceContainerHighest),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
