import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/exam_entity.dart';

/// Fields for a single question (statement, options, correct answer,
/// points). Content only: the mobile stepper and the desktop split view
/// both host it.
class QuestionForm extends StatefulWidget {
  const QuestionForm({
    super.key,
    required this.question,
    required this.onChanged,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  final ExamQuestion question;
  final void Function(ExamQuestion) onChanged;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;

  @override
  State<QuestionForm> createState() => QuestionFormStateX();
}

class QuestionFormStateX extends State<QuestionForm> {
  late final _statementController = TextEditingController(
    text: widget.question.statement,
  );
  late final _pointsController = TextEditingController(
    text: widget.question.points?.toString() ?? '',
  );
  late List<TextEditingController> _optionControllers;
  late String _correctOption;

  @override
  void initState() {
    super.initState();
    _optionControllers = [
      for (final o in widget.question.options)
        TextEditingController(text: o.text),
    ];
    _correctOption = widget.question.correctOption;
  }

  // The form is now keyed by a stable `uiKey` (see `DraftQuestion`), so
  // `initState` won't rerun just because an option was added/removed on the
  // SAME question — controllers have to be resynced here instead.
  @override
  void didUpdateWidget(covariant QuestionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question.options.length != oldWidget.question.options.length) {
      for (final c in _optionControllers) {
        c.dispose();
      }
      _optionControllers = [
        for (final o in widget.question.options)
          TextEditingController(text: o.text),
      ];
    } else {
      for (var i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text != widget.question.options[i].text) {
          _optionControllers[i].text = widget.question.options[i].text;
        }
      }
    }
    if (widget.question.correctOption != oldWidget.question.correctOption) {
      _correctOption = widget.question.correctOption;
    }
  }

  @override
  void dispose() {
    _statementController.dispose();
    _pointsController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.question.copyWith(
        statement: _statementController.text,
        correctOption: _correctOption,
        points: double.tryParse(_pointsController.text.trim()),
        options: [
          for (var i = 0; i < widget.question.options.length; i++)
            QuestionOption(
              letter: widget.question.options[i].letter,
              text: _optionControllers[i].text,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enunciado', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              AppTextField(
                controller: _statementController,
                label: 'Enunciado de la pregunta',
                helperText: 'Escribe aquí la pregunta que verá el estudiante.',
                required: true,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El enunciado es obligatorio.'
                    : null,
                onChanged: (_) => _emit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Opciones de respuesta',
                      style: textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    '${widget.question.options.length} opciones',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < widget.question.options.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: widget.question.options[i].letter == _correctOption
                        ? AppColors.successBg
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: widget.question.options[i].letter,
                        groupValue: _correctOption.isEmpty
                            ? null
                            : _correctOption,
                        onChanged: (value) {
                          setState(() => _correctOption = value ?? '');
                          _emit();
                        },
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          widget.question.options[i].letter,
                          textAlign: TextAlign.center,
                          style:
                              widget.question.options[i].letter ==
                                  _correctOption
                              ? textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: _optionControllers[i],
                          label: 'Opción ${widget.question.options[i].letter}',
                          hint: 'Texto de la opción',
                          onChanged: (_) => _emit(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: widget.question.options.length > 2
                            ? 'Quitar opción'
                            : 'Mínimo 2 opciones',
                        onPressed: widget.question.options.length > 2
                            ? () => widget.onRemoveOption(i)
                            : null,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: '+ Agregar opción',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.add,
                  onPressed: widget.onAddOption,
                ),
              ),
              const SizedBox(height: 8),
              if (_correctOption.isEmpty)
                Text(
                  'Marca cuál opción es la correcta.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Respuesta correcta: $_correctOption',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _pointsController,
          label: 'Puntos (opcional)',
          helperText:
              'Déjalo en blanco para repartir el puntaje equitativamente.',
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
