import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../providers/gradebook_provider.dart';
import 'grade_labels.dart';

double? _parse(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Runs [action]; on success closes the form and confirms, on failure
/// shows the API error and keeps the form open.
Future<void> _submit(
  BuildContext context,
  Future<AppException?> Function() action,
  String success,
) async {
  final error = await action();
  if (!context.mounted) return;
  if (error != null) {
    context.showApiError(error);
  } else {
    Navigator.of(context).pop(true);
    context.showSuccess(success);
  }
}

/// The teacher's observation about a student in a class (blank removes it).
class ObservationForm extends StatefulWidget {
  const ObservationForm({super.key, required this.report});

  final StudentGradeReport report;

  @override
  State<ObservationForm> createState() => _ObservationFormState();
}

class _ObservationFormState extends State<ObservationForm> {
  late final _text = TextEditingController(
    text: widget.report.observation?.text ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _submit(
      context,
      () => context.read<GradebookProvider>().saveObservation(
        widget.report.teachingPeriodId,
        widget.report.student.id,
        _text.text,
      ),
      _text.text.trim().isEmpty
          ? 'Observación borrada.'
          : 'Observación guardada.',
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Observaciones',
      actions: [
        AppButton(label: 'Guardar', isLoading: _saving, onPressed: _save),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sobre ${widget.report.student.fullName} en esta clase. Solo la '
            'ves tú; déjala en blanco para borrarla.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _text,
            label: 'Observación',
            maxLines: 6,
            maxLength: 1000,
            autofocus: true,
          ),
        ],
      ),
    );
  }
}

/// An activity grade set by hand, with the teacher's comment.
class GradeEditForm extends StatefulWidget {
  const GradeEditForm({super.key, required this.detail});

  final GradeDetailEntity detail;

  @override
  State<GradeEditForm> createState() => _GradeEditFormState();
}

class _GradeEditFormState extends State<GradeEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _grade = TextEditingController(
    text: widget.detail.evaluation.earned == null
        ? ''
        : compactNumber(widget.detail.evaluation.earned!),
  );
  late final _comment = TextEditingController(
    text: widget.detail.evaluation.comment ?? '',
  );
  bool _saving = false;

  double get _max => widget.detail.evaluation.maximumScore;

  @override
  void dispose() {
    _grade.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _submit(
      context,
      () => context.read<GradebookProvider>().saveActivityGrade(
        widget.detail,
        grade: _parse(_grade.text)!,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      ),
      'Nota guardada.',
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasRubric = widget.detail.rubric.isNotEmpty;
    return AppFormFrame(
      title: 'Editar nota',
      actions: [
        AppButton(label: 'Guardar', isLoading: _saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasRubric)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Esta actividad tiene rúbrica: una nota escrita a mano '
                  'reemplaza la calculada hasta que vuelvas a calificar con '
                  'la rúbrica.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ),
            AppTextField(
              controller: _grade,
              label: 'Nota (de 0 a ${compactNumber(_max)})',
              required: true,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final value = _parse(v ?? '');
                if (value == null) return 'Escribe la nota.';
                if (value < 0 || value > _max) {
                  return 'Debe estar entre 0 y ${compactNumber(_max)}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _comment,
              label: 'Comentario para el estudiante',
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Defines an activity's rubric: criteria whose weights add up to 100.
/// Existing criteria keep their id, so renaming one keeps its scores.
class RubricForm extends StatefulWidget {
  const RubricForm({super.key, required this.detail});

  final GradeDetailEntity detail;

  @override
  State<RubricForm> createState() => _RubricFormState();
}

class _CriterionDraft {
  _CriterionDraft({this.id, String name = '', String weight = ''})
    : name = TextEditingController(text: name),
      weight = TextEditingController(text: weight);

  final int? id;
  final TextEditingController name;
  final TextEditingController weight;

  void dispose() {
    name.dispose();
    weight.dispose();
  }
}

class _RubricFormState extends State<RubricForm> {
  late final List<_CriterionDraft> _criteria = widget.detail.rubric.isEmpty
      ? [_CriterionDraft(), _CriterionDraft()]
      : [
          for (final c in widget.detail.rubric)
            _CriterionDraft(
              id: c.id,
              name: c.name,
              weight: compactNumber(c.weight),
            ),
        ];
  bool _saving = false;

  double get _total =>
      _criteria.fold(0, (sum, c) => sum + (_parse(c.weight.text) ?? 0));

  @override
  void dispose() {
    for (final c in _criteria) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final inputs = <RubricCriterionInput>[];
    for (final c in _criteria) {
      final name = c.name.text.trim();
      final weight = _parse(c.weight.text);
      if (name.isEmpty || weight == null || weight <= 0) {
        context.showWarning(
          'Cada criterio necesita nombre y un peso mayor a 0.',
        );
        return;
      }
      inputs.add(RubricCriterionInput(id: c.id, name: name, weight: weight));
    }
    if ((_total - 100).abs() > 0.001) {
      context.showWarning(
        'Los pesos deben sumar 100% (ahora ${compactNumber(_total)}%).',
      );
      return;
    }
    setState(() => _saving = true);
    await _submit(
      context,
      () => context.read<GradebookProvider>().saveRubric(widget.detail, inputs),
      'Rúbrica guardada.',
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = _total;
    final valid = (total - 100).abs() < 0.001;

    return AppFormFrame(
      title: widget.detail.rubric.isEmpty ? 'Crear rúbrica' : 'Editar rúbrica',
      actions: [
        AppButton(
          label: 'Guardar rúbrica',
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aplica a todos los estudiantes de "${widget.detail.evaluation.name}". '
            'Cada criterio se califica de 0 a '
            '${compactNumber(widget.detail.evaluation.maximumScore)} y la nota '
            'es el promedio ponderado.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final (i, c) in _criteria.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: c.name,
                      label: 'Criterio ${i + 1}',
                      hint: 'Ej. Ortografía',
                      maxLength: 150,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 92,
                    child: AppTextField(
                      controller: c.weight,
                      label: 'Peso %',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar criterio',
                    onPressed: _criteria.length > 1
                        ? () => setState(() => _criteria.removeAt(i).dispose())
                        : null,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _criteria.length >= 10
                    ? null
                    : () => setState(() => _criteria.add(_CriterionDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar criterio'),
              ),
              const Spacer(),
              Icon(
                valid ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color: valid ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                'Total ${compactNumber(total)}%',
                style: textTheme.labelLarge?.copyWith(
                  color: valid ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Scores a student on each rubric criterion; the grade is computed and
/// shown live (the backend computes the official one the same way).
class RubricScoresForm extends StatefulWidget {
  const RubricScoresForm({super.key, required this.detail});

  final GradeDetailEntity detail;

  @override
  State<RubricScoresForm> createState() => _RubricScoresFormState();
}

class _RubricScoresFormState extends State<RubricScoresForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<int, TextEditingController> _scores = {
    for (final c in widget.detail.rubric)
      c.id: TextEditingController(
        text: c.score == null ? '' : compactNumber(c.score!),
      ),
  };
  late final _comment = TextEditingController(
    text: widget.detail.evaluation.comment ?? '',
  );
  bool _saving = false;

  double get _max => widget.detail.evaluation.maximumScore;

  double? get _grade {
    var total = 0.0;
    for (final c in widget.detail.rubric) {
      final score = _parse(_scores[c.id]!.text);
      if (score == null) return null;
      total += score * c.weight / 100;
    }
    return total;
  }

  @override
  void dispose() {
    for (final c in _scores.values) {
      c.dispose();
    }
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _submit(
      context,
      () => context.read<GradebookProvider>().scoreWithRubric(
        widget.detail,
        scores: {for (final e in _scores.entries) e.key: _parse(e.value.text)!},
        comment: _comment.text.trim(),
      ),
      'Nota calculada con la rúbrica.',
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grade = _grade;

    return AppFormFrame(
      title: 'Calificar con rúbrica',
      actions: [
        AppButton(label: 'Guardar nota', isLoading: _saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.detail.student.fullName} · cada criterio de 0 a '
              '${compactNumber(_max)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final c in widget.detail.rubric)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text.rich(
                          TextSpan(
                            text: c.name,
                            style: textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: '  ${compactNumber(c.weight)}%',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: AppTextField(
                        controller: _scores[c.id],
                        label: 'Puntaje',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final value = _parse(v ?? '');
                          if (value == null) return 'Falta';
                          if (value < 0 || value > _max) {
                            return '0–${compactNumber(_max)}';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Nota resultante', style: textTheme.bodyMedium),
                  ),
                  Text(
                    grade == null
                        ? '—'
                        : '${grade.toStringAsFixed(2)} / ${compactNumber(_max)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _comment,
              label: 'Comentario para el estudiante',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
}
