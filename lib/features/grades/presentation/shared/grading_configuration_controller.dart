import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/gradebook_provider.dart';
import '../providers/grading_provider.dart';
import 'grading_scale_form.dart';

/// Editable grading configuration for one teaching period (§54, §84):
/// chosen scale, passing grade and per-category weights. The UI keeps the
/// "Total: 100%" rule front and center and never computes the official
/// grade itself. Owned by the page entry point so edits survive a
/// mobile <-> desktop switch.
class GradingConfigurationController extends ChangeNotifier {
  GradingConfigurationController(this.teachingPeriodId);

  final int teachingPeriodId;
  final Map<int, TextEditingController> weightControllers = {};
  final passingGradeController = TextEditingController();

  int? _scaleId;
  int? get scaleId => _scaleId;

  bool _saving = false;
  bool get saving => _saving;

  bool _dirty = false;

  /// Edited since load or the last save.
  bool get dirty => _dirty;

  /// The class's evaluations by category (to show what each weight
  /// covers); null while loading or if they couldn't be read.
  Map<int, List<EvaluationSummaryEntity>>? _evaluations;
  Map<int, List<EvaluationSummaryEntity>>? get evaluationsByCategory =>
      _evaluations;

  bool _disposed = false;

  double weightOf(int categoryId) =>
      double.tryParse(weightControllers[categoryId]?.text.trim() ?? '') ?? 0;

  double get totalWeight => weightControllers.values.fold(
    0,
    (sum, c) => sum + (double.tryParse(c.text.trim()) ?? 0),
  );

  double? get passingGrade =>
      double.tryParse(passingGradeController.text.trim().replaceAll(',', '.'));

  GradingScaleEntity? scaleIn(List<GradingScaleEntity> scales) =>
      scales.where((s) => s.id == _scaleId).firstOrNull;

  /// Why the passing grade can't be saved, or null if it's fine.
  String? passingGradeError(List<GradingScaleEntity> scales) {
    final text = passingGradeController.text.trim();
    if (text.isEmpty) return null;
    final value = passingGrade;
    final scale = scaleIn(scales);
    if (value == null) return 'Escribe un número.';
    if (scale != null &&
        (value < scale.minimumValue || value > scale.maximumValue)) {
      return 'Debe estar entre ${_n(scale.minimumValue)} y '
          '${_n(scale.maximumValue)}.';
    }
    return null;
  }

  /// Fills the form from the class's configuration. Scales, categories,
  /// the configuration and the evaluations come from memory when already
  /// read; [refresh] ("retry") reads them again.
  Future<void> load(BuildContext context, {bool refresh = false}) async {
    final grading = context.read<GradingProvider>();
    final gradebook = context.read<GradebookProvider>();
    await Future.wait([
      refresh ? grading.refreshCatalog() : grading.ensureCatalog(),
      refresh
          ? grading.refreshConfiguration(teachingPeriodId)
          : grading.ensureConfiguration(teachingPeriodId),
    ]);
    if (_disposed) return;
    final config = grading.configuration(teachingPeriodId).data;
    _scaleId = config?.scale.id;
    passingGradeController.text = config?.passingGrade == null
        ? ''
        : _n(config!.passingGrade!);
    for (final category in grading.categories) {
      final weight = config?.weights
          .where((w) => w.evaluationCategoryId == category.id)
          .map((w) => w.weight)
          .firstOrNull;
      (weightControllers[category.id] ??= TextEditingController()).text =
          weight != null ? _n(weight) : '';
    }
    _dirty = false;
    _notify();
    await gradebook.ensureEvaluations(teachingPeriodId);
    if (_disposed) return;
    final evaluations = gradebook.evaluations(teachingPeriodId);
    if (evaluations == null) {
      _evaluations = null;
    } else {
      _evaluations = {};
      for (final e in evaluations) {
        (_evaluations![e.categoryId] ??= []).add(e);
      }
    }
    _notify();
  }

  void selectScale(int? id) {
    _scaleId = id;
    _dirty = true;
    _notify();
  }

  /// Call when a field changes, so totals and validation re-render.
  void changed() {
    _dirty = true;
    _notify();
  }

  /// Sets a weight from a slider or stepper.
  void setWeight(int categoryId, double value) {
    weightControllers[categoryId]?.text = _n(value);
    changed();
  }

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
    final grading = context.read<GradingProvider>();
    if (_scaleId == null) {
      context.showWarning('Selecciona una escala de calificación.');
      return;
    }
    final passingError = passingGradeError(grading.scales);
    if (passingError != null) {
      context.showWarning('Nota mínima: $passingError');
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
    _notify();
    final error = await grading.saveConfiguration(
      teachingPeriodId,
      gradingScaleId: _scaleId!,
      weights: weights,
      passingGrade: passingGrade,
    );
    if (_disposed) return;
    _saving = false;
    if (error == null) _dirty = false;
    _notify();
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        totalWeight == 100
            ? 'Configuración guardada.'
            : 'Configuración guardada. Las notas se calculan cuando los '
                  'pesos sumen 100%.',
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _disposed = true;
    for (final c in weightControllers.values) {
      c.dispose();
    }
    passingGradeController.dispose();
    super.dispose();
  }
}
