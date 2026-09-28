import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../providers/grading_provider.dart';
import 'grading_configuration_controller.dart';

/// Resolves the configuration's loading/error states and hands the loaded
/// state to [builder]; the mobile and desktop tabs only arrange the cards.
class GradingConfigurationStateView extends StatelessWidget {
  const GradingConfigurationStateView({
    super.key,
    required this.controller,
    required this.builder,
  });

  final GradingConfigurationController controller;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final configState = context.watch<GradingProvider>().configState;
    switch (configState.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: configState.error!,
          onRetry: () => controller.load(context.read<GradingProvider>()),
        );
      case DetailStatus.success:
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => builder(context),
        );
    }
  }
}

/// Scale picker card. [onCreateScale] is how the current platform presents
/// the "new scale" form.
class GradingScaleCard extends StatelessWidget {
  const GradingScaleCard({
    super.key,
    required this.controller,
    required this.onCreateScale,
  });

  final GradingConfigurationController controller;
  final VoidCallback onCreateScale;

  @override
  Widget build(BuildContext context) {
    final scales = context.watch<GradingProvider>().scales;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Escala de calificación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onCreateScale,
                child: const Text('Nueva escala'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'El rango numérico en el que calificarás (ej. de 0 a 5). Las '
            'escalas son compartidas por todo el colegio, no solo por '
            'esta clase.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppDropdown<int>(
            value: controller.scaleId,
            items: [for (final s in scales) s.id],
            itemLabel: (id) {
              final scale = scales.firstWhere((s) => s.id == id);
              return '${scale.name} (${scale.minimumValue.toStringAsFixed(0)}-'
                  '${scale.maximumValue.toStringAsFixed(0)})';
            },
            onChanged: controller.selectScale,
          ),
        ],
      ),
    );
  }
}

/// Category weights card with the running "Total: N%" and the save button.
class GradingWeightsCard extends StatelessWidget {
  const GradingWeightsCard({super.key, required this.controller});

  final GradingConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<GradingProvider>().categories;
    final total = controller.totalWeight;
    final isComplete = total == 100;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ponderaciones', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Los pesos deben sumar 100% (se admiten configuraciones parciales).',
          ),
          const SizedBox(height: 16),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text(category.name)),
                  SizedBox(
                    width: 100,
                    child: AppTextField(
                      controller: controller.weightControllers[category.id],
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('%'),
                        ),
                      ),
                      onChanged: (_) => controller.weightsChanged(),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${total.toStringAsFixed(0)}%',
                  style: textTheme.titleMedium?.copyWith(
                    color: isComplete ? colors.primary : colors.error,
                  ),
                ),
              ),
              if (!isComplete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 14, color: colors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Deben sumar 100%.',
                      style: textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Guardar configuración',
            isLoading: controller.saving,
            onPressed: () => controller.save(context),
          ),
        ],
      ),
    );
  }
}
