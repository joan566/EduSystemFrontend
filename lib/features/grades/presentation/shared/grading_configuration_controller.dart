import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';
import 'grading_scale_form.dart';

/// Editable grading configuration for one teaching period (§54, §84):
/// chosen scale + per-category weights. The UI keeps the "Total: 100%"
/// rule front and center and never computes the official grade itself.
/// Owned by the page entry point so edits survive a mobile <-> desktop
/// switch.
class GradingConfigurationController extends ChangeNotifier {
  GradingConfigurationController(this.teachingPeriodId);

  final int teachingPeriodId;
  final Map<int, TextEditingController> weightControllers = {};

  int? _scaleId;
  int? get scaleId => _scaleId;

  bool _saving = false;
  bool get saving => _saving;

  bool _disposed = false;

  double get totalWeight => weightControllers.values.fold(
    0,
    (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0),
  );

  Future<void> load(GradingProvider provider) async {
    await provider.loadCatalog();
    await provider.loadConfiguration(teachingPeriodId);
    if (_disposed) return;
    final config = provider.configState.data;
    _scaleId = config?.scale.id;
    for (final category in provider.categories) {
      final weight = config?.weights
          .where((w) => w.evaluationCategoryId == category.id)
          .map((w) => w.weight)
          .firstOrNull;
      weightControllers[category.id] = TextEditingController(
        text: weight != null ? weight.toStringAsFixed(0) : '',
      );
    }
    notifyListeners();
  }

  void selectScale(int? id) {
    _scaleId = id;
    notifyListeners();
  }

  /// Call when a weight field changes, so the running total re-renders.
  void weightsChanged() => notifyListeners();

  Future<void> createScale(
    BuildContext context,
    GradingScaleFormResult data,
  ) async {
    final error = await context.read<GradingProvider>().createScale(
      name: data.name,
      minimumValue: data.minimumValue,
      maximumValue: data.maximumValue,
    );
    if (!context.mounted) return;
    if (error != null) context.showApiError(error);
  }

  Future<void> save(BuildContext context) async {
    if (_scaleId == null) {
      context.showWarning('Selecciona una escala de calificación.');
      return;
    }
    final weights = [
      for (final entry in weightControllers.entries)
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
    _saving = true;
    notifyListeners();
    final error = await context.read<GradingProvider>().saveConfiguration(
      teachingPeriodId,
      gradingScaleId: _scaleId!,
      weights: weights,
    );
    if (_disposed) return;
    _saving = false;
    notifyListeners();
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Configuración de calificación guardada.');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final c in weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
