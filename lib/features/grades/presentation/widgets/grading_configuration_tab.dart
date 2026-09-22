import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';

/// Grading scale + category weights for a teaching period (§54, §84): the
/// UI keeps the "Total: 100%" rule front and center, and never computes
/// the official grade itself — that stays server-side.
class GradingConfigurationTab extends StatefulWidget {
  const GradingConfigurationTab({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<GradingConfigurationTab> createState() => _GradingConfigurationTabState();
}

class _GradingConfigurationTabState extends State<GradingConfigurationTab> {
  int? _scaleId;
  final Map<int, TextEditingController> _weightControllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GradingProvider>();
      await provider.loadCatalog();
      await provider.loadConfiguration(widget.teachingPeriodId);
      _applyConfig(provider.configState.data);
    });
  }

  void _applyConfig(GradingConfigurationEntity? config) {
    if (!mounted) return;
    setState(() {
      _scaleId = config?.scale.id;
      for (final category in context.read<GradingProvider>().categories) {
        final weight = config?.weights
            .where((w) => w.evaluationCategoryId == category.id)
            .map((w) => w.weight)
            .firstOrNull;
        _weightControllers[category.id] = TextEditingController(
          text: weight != null ? weight.toStringAsFixed(0) : '',
        );
      }
    });
  }

  double get _totalWeight => _weightControllers.values.fold(
    0,
    (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0),
  );

  Future<void> _createScale() async {
    final result = await showAppDialog(context, child: const _ScaleForm());
    if (result == null) return;
    final data = result as ({String name, double minimumValue, double maximumValue});
    final error = await context.read<GradingProvider>().createScale(
      name: data.name,
      minimumValue: data.minimumValue,
      maximumValue: data.maximumValue,
    );
    if (!mounted) return;
    if (error != null) context.showApiError(error);
  }

  Future<void> _save() async {
    if (_scaleId == null) {
      context.showWarning('Selecciona una escala de calificación.');
      return;
    }
    final weights = [
      for (final entry in _weightControllers.entries)
        if ((double.tryParse(entry.value.text.trim()) ?? 0) > 0)
          CategoryWeight(
            evaluationCategoryId: entry.key,
            weight: double.parse(entry.value.text.trim()),
          ),
    ];
    if (weights.isEmpty) {
      context.showWarning('Asigna al menos un peso.');
      return;
    }
    setState(() => _saving = true);
    final error = await context.read<GradingProvider>().saveConfiguration(
      widget.teachingPeriodId,
      gradingScaleId: _scaleId!,
      weights: weights,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Configuración de calificación guardada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GradingProvider>();
    final configState = provider.configState;

    if (configState.status == DetailStatus.loading || configState.status == DetailStatus.initial) {
      return const AppLoading();
    }
    if (configState.status == DetailStatus.error) {
      return AppErrorState(
        exception: configState.error!,
        onRetry: () => context.read<GradingProvider>().loadConfiguration(widget.teachingPeriodId),
      );
    }

    final total = _totalWeight;
    final isComplete = total == 100;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Escala de calificación', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton(onPressed: _createScale, child: const Text('Nueva escala')),
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
                value: _scaleId,
                items: [for (final s in provider.scales) s.id],
                itemLabel: (id) {
                  final scale = provider.scales.firstWhere((s) => s.id == id);
                  return '${scale.name} (${scale.minimumValue.toStringAsFixed(0)}-'
                      '${scale.maximumValue.toStringAsFixed(0)})';
                },
                onChanged: (value) => setState(() => _scaleId = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ponderaciones', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Los pesos deben sumar 100% (se admiten configuraciones parciales).'),
              const SizedBox(height: 16),
              for (final category in provider.categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(category.name)),
                      SizedBox(
                        width: 100,
                        child: AppTextField(
                          controller: _weightControllers[category.id],
                          hint: '0',
                          keyboardType: TextInputType.number,
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Align(alignment: Alignment.centerRight, child: Text('%')),
                          ),
                          onChanged: (_) => setState(() {}),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isComplete
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  if (!isComplete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deben sumar 100%.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Guardar configuración', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScaleForm extends StatefulWidget {
  const _ScaleForm();

  @override
  State<_ScaleForm> createState() => _ScaleFormState();
}

class _ScaleFormState extends State<_ScaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minController = TextEditingController(text: '0');
  final _maxController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final min = double.parse(_minController.text.trim());
    final max = double.parse(_maxController.text.trim());
    if (min >= max) {
      context.showWarning('El mínimo debe ser menor que el máximo.');
      return;
    }
    Navigator.of(
      context,
    ).pop((name: _nameController.text.trim(), minimumValue: min, maximumValue: max));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Nueva escala',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Nombre',
              required: true,
              hint: 'Ej. Escala 0-5',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _minController,
                    label: 'Mínimo',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _maxController,
                    label: 'Máximo',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
