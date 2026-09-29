import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/exam_entity.dart';

/// Editor of the selected question: statement, options (click a letter to
/// mark the correct answer), optional points and what's still missing.
class QuestionEditorPanel extends StatefulWidget {
  const QuestionEditorPanel({
    super.key,
    required this.question,
    required this.total,
    required this.onChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onPrevious,
    required this.onNext,
    required this.onDelete,
  });

  final ExamQuestion question;
  final int total;
  final ValueChanged<ExamQuestion> onChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;

  /// Null at the ends of the list / when it's the only question.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onDelete;

  @override
  State<QuestionEditorPanel> createState() => _QuestionEditorPanelState();
}

class _QuestionEditorPanelState extends State<QuestionEditorPanel> {
  late final _statement = TextEditingController(
    text: widget.question.statement,
  );
  late final _points = TextEditingController(
    text: widget.question.points?.toString() ?? '',
  );
  late List<TextEditingController> _options = _optionControllers();

  List<TextEditingController> _optionControllers() => [
    for (final o in widget.question.options)
      TextEditingController(text: o.text),
  ];

  // Keyed by the draft's stable `uiKey`: adding/removing an option (which
  // relabels the rest) arrives here, not in `initState`.
  @override
  void didUpdateWidget(covariant QuestionEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final options = widget.question.options;
    if (options.length != oldWidget.question.options.length) {
      for (final c in _options) {
        c.dispose();
      }
      _options = _optionControllers();
    } else {
      for (var i = 0; i < _options.length; i++) {
        if (_options[i].text != options[i].text) {
          _options[i].text = options[i].text;
        }
      }
    }
  }

  @override
  void dispose() {
    _statement.dispose();
    _points.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit({String? correctOption}) {
    final q = widget.question;
    widget.onChanged(
      q.copyWith(
        statement: _statement.text,
        correctOption: correctOption ?? q.correctOption,
        points: double.tryParse(_points.text.trim().replaceAll(',', '.')),
        options: [
          for (var i = 0; i < q.options.length; i++)
            QuestionOption(letter: q.options[i].letter, text: _options[i].text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 12, 14),
            child: Row(
              children: [
                Flexible(
                  child: Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      text: 'Pregunta ${q.questionNumber}',
                      style: textTheme.titleLarge,
                      children: [
                        TextSpan(
                          text: '  de ${widget.total}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Selección múltiple',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Anterior (Alt+↑)',
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: 'Siguiente (Alt+↓)',
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: widget.onDelete != null
                      ? 'Eliminar pregunta'
                      : 'El examen debe tener al menos una pregunta',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Align(
                alignment: Alignment.topLeft,
                // Long lines are hard to read; cap the form's width.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Enunciado', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _statement,
                        minLines: 3,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Escribe la pregunta que verá el '
                              'estudiante.',
                        ),
                        onChanged: (_) => _emit(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Opciones de respuesta',
                            style: textTheme.labelLarge,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Haz clic en la letra para marcar la respuesta '
                              'correcta.',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < q.options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OptionRow(
                            letter: q.options[i].letter,
                            controller: _options[i],
                            correct: q.correctOption == q.options[i].letter,
                            canRemove: q.options.length > 2,
                            onMarkCorrect: () =>
                                _emit(correctOption: q.options[i].letter),
                            onChanged: _emit,
                            onRemove: () => widget.onRemoveOption(i),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: widget.onAddOption,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar opción'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _points,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Puntos (opcional)',
                                isDense: true,
                              ),
                              onChanged: (_) => _emit(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Déjalo vacío para repartir el puntaje del '
                                'examen en partes iguales.',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _Completeness(question: q),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.letter,
    required this.controller,
    required this.correct,
    required this.canRemove,
    required this.onMarkCorrect,
    required this.onChanged,
    required this.onRemove,
  });

  final String letter;
  final TextEditingController controller;
  final bool correct;
  final bool canRemove;
  final VoidCallback onMarkCorrect;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final correct = widget.correct;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Row(
        children: [
          Tooltip(
            message: correct
                ? 'Respuesta correcta'
                : 'Marcar ${widget.letter} como correcta',
            child: Semantics(
              button: true,
              selected: correct,
              label: 'Marcar la opción ${widget.letter} como correcta',
              child: InkWell(
                onTap: widget.onMarkCorrect,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: correct ? AppColors.success : colors.surface,
                    border: Border.all(
                      color: correct ? AppColors.success : colors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: correct
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : Text(
                          widget.letter,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Texto de la opción ${widget.letter}',
                isDense: true,
                // Theme fields are filled; the correct one takes the
                // success tint instead.
                fillColor: correct ? AppColors.successBg : null,
                suffixIcon: correct
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'Correcta',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          SizedBox(
            width: 44,
            child: widget.canRemove
                ? AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovering ? 1 : 0.3,
                    child: IconButton(
                      tooltip: 'Quitar opción ${widget.letter}',
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Completeness extends StatelessWidget {
  const _Completeness({required this.question});

  final ExamQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final complete = question.isComplete;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.info_outline,
            size: 20,
            color: complete ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              complete
                  ? 'Pregunta completa. Respuesta correcta: '
                        '${question.correctOption}.'
                  : 'Falta: ${question.missingFields.join(', ').toLowerCase()}.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
