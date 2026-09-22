import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';

const _defaultLetters = ['A', 'B', 'C', 'D'];

ExamQuestion _blankQuestion(int number, int optionCount) => ExamQuestion(
  questionNumber: number,
  statement: '',
  correctOption: '',
  options: [
    for (var i = 0; i < optionCount; i++)
      QuestionOption(
        letter: _defaultLetters[i % _defaultLetters.length],
        text: '',
      ),
  ],
);

String _letterFor(int index) => String.fromCharCode('A'.codeUnitAt(0) + index);

/// A question mid-edit, identified by a UI-only [uiKey] that never changes.
/// `questionNumber` gets recomputed on every add/remove so the list stays
/// contiguously numbered — keying widgets by `uiKey` instead is what keeps a
/// question's text controllers attached to the right question when an
/// earlier one is deleted and everything after it shifts down.
class _DraftQuestion {
  _DraftQuestion({required this.uiKey, required this.data});

  final Key uiKey;
  final ExamQuestion data;
}

/// Question bank editor: a two-column list + editor on desktop for fast
/// bulk entry, a full-screen one-question-at-a-time stepper on mobile.
///
/// [embedded] is used only by the exam-creation wizard (`ExamBuilderPage`):
/// it swaps the persistent save action for a "continue" one (no backend
/// call — the wizard's Review step does the actual save) and reports every
/// draft change via [onDraftsChanged] so Review always has the latest data.
/// Used without those (as `ExamDetailPage` does today) it behaves exactly
/// as before: edits a single existing exam's questions and saves them via
/// [ExamsProvider.saveQuestions] (a full replace, per the API).
class QuestionsEditor extends StatefulWidget {
  const QuestionsEditor({
    super.key,
    required this.examId,
    required this.exam,
    this.embedded = false,
    this.onDraftsChanged,
    this.onContinue,
  });

  final int examId;
  final ExamEntity exam;
  final bool embedded;
  final ValueChanged<List<ExamQuestion>>? onDraftsChanged;
  final VoidCallback? onContinue;

  @override
  State<QuestionsEditor> createState() => _QuestionsEditorState();
}

class _QuestionsEditorState extends State<QuestionsEditor> {
  late List<_DraftQuestion> _drafts;
  int _selected = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.exam.questions.isNotEmpty
        ? widget.exam.questions
        : [
            for (var i = 1; i <= widget.exam.numberOfQuestions; i++)
              _blankQuestion(i, widget.exam.optionCount),
          ];
    _drafts = [
      for (final q in seed) _DraftQuestion(uiKey: UniqueKey(), data: q),
    ];
    if (widget.onDraftsChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportDrafts());
    }
  }

  void _reportDrafts() =>
      widget.onDraftsChanged?.call([for (final d in _drafts) d.data]);

  List<_DraftQuestion> _renumber(List<_DraftQuestion> drafts) => [
    for (var i = 0; i < drafts.length; i++)
      _DraftQuestion(
        uiKey: drafts[i].uiKey,
        data: drafts[i].data.copyWith(questionNumber: i + 1),
      ),
  ];

  void _updateQuestion(int index, ExamQuestion updated) {
    setState(
      () => _drafts[index] = _DraftQuestion(
        uiKey: _drafts[index].uiKey,
        data: updated,
      ),
    );
    _reportDrafts();
  }

  void _addQuestion() {
    setState(() {
      _drafts = _renumber([
        ..._drafts,
        _DraftQuestion(
          uiKey: UniqueKey(),
          data: _blankQuestion(_drafts.length + 1, widget.exam.optionCount),
        ),
      ]);
      _selected = _drafts.length - 1;
    });
    _reportDrafts();
  }

  Future<void> _removeQuestion(int index) async {
    if (_drafts.length <= 1) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar pregunta',
      message:
          'Se perderá el contenido de esta pregunta. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _drafts = _renumber([..._drafts]..removeAt(index));
      _selected = _selected.clamp(0, _drafts.length - 1);
    });
    _reportDrafts();
  }

  void _addOption(int questionIndex) {
    final q = _drafts[questionIndex].data;
    _updateQuestion(
      questionIndex,
      q.copyWith(
        options: [
          ...q.options,
          QuestionOption(letter: _letterFor(q.options.length), text: ''),
        ],
      ),
    );
  }

  /// Removing an option relabels every remaining one by its *new* position
  /// (never keeping stale letters) and remaps `correctOption` to follow
  /// whichever option it used to point at — otherwise, after a removal, the
  /// correct-answer string can silently end up pointing at the wrong option.
  void _removeOption(int questionIndex, int optionIndex) {
    final q = _drafts[questionIndex].data;
    if (q.options.length <= 2) return;
    final removedLetter = q.options[optionIndex].letter;
    final remaining = [...q.options]..removeAt(optionIndex);
    final relabeled = [
      for (var i = 0; i < remaining.length; i++)
        QuestionOption(letter: _letterFor(i), text: remaining[i].text),
    ];
    String newCorrectOption;
    if (q.correctOption == removedLetter) {
      newCorrectOption = '';
    } else {
      final oldPosition = q.options.indexWhere(
        (o) => o.letter == q.correctOption,
      );
      final newPosition = oldPosition > optionIndex
          ? oldPosition - 1
          : oldPosition;
      newCorrectOption = relabeled[newPosition].letter;
    }
    _updateQuestion(
      questionIndex,
      q.copyWith(options: relabeled, correctOption: newCorrectOption),
    );
  }

  Future<void> _save() async {
    final incomplete = _drafts.where((d) => !d.data.isComplete).length;
    if (incomplete > 0) {
      final proceed = await showAppConfirmDialog(
        context,
        title: 'Preguntas incompletas',
        message:
            'El examen tiene $incomplete pregunta(s) incompleta(s). '
            '¿Guardar de todas formas? No podrás generar hojas hasta completarlas.',
        confirmLabel: 'Guardar de todas formas',
        isDestructive: false,
      );
      if (!proceed) return;
    }
    setState(() => _saving = true);
    final error = await context.read<ExamsProvider>().saveQuestions(
      widget.examId,
      [for (final d in _drafts) d.data],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Preguntas guardadas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimaryAction = widget.embedded
        ? (widget.onContinue ?? _save)
        : _save;
    return ResponsiveBuilder(
      mobile: (_) => _MobileEditor(
        drafts: _drafts,
        embedded: widget.embedded,
        onChanged: _updateQuestion,
        onAdd: _addQuestion,
        onDelete: _removeQuestion,
        onAddOption: _addOption,
        onRemoveOption: _removeOption,
        onSave: onPrimaryAction,
        saving: _saving,
      ),
      desktop: (_) => _DesktopEditor(
        drafts: _drafts,
        selected: _selected,
        embedded: widget.embedded,
        onSelect: (i) => setState(() => _selected = i),
        onChanged: _updateQuestion,
        onAdd: _addQuestion,
        onDelete: _removeQuestion,
        onAddOption: _addOption,
        onRemoveOption: _removeOption,
        onSave: onPrimaryAction,
        saving: _saving,
      ),
    );
  }
}

class _DesktopEditor extends StatelessWidget {
  const _DesktopEditor({
    required this.drafts,
    required this.selected,
    required this.embedded,
    required this.onSelect,
    required this.onChanged,
    required this.onAdd,
    required this.onDelete,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSave,
    required this.saving,
  });

  final List<_DraftQuestion> drafts;
  final int selected;
  final bool embedded;
  final void Function(int) onSelect;
  final void Function(int, ExamQuestion) onChanged;
  final VoidCallback onAdd;
  final void Function(int) onDelete;
  final void Function(int) onAddOption;
  final void Function(int, int) onRemoveOption;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: embedded ? 'Continuar a revisar' : 'Guardar preguntas',
              isLoading: saving,
              onPressed: onSave,
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 260,
                child: ListView.builder(
                  itemCount: drafts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == drafts.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: AppButton(
                          label: '+ Agregar pregunta',
                          variant: AppButtonVariant.outlined,
                          icon: Icons.add,
                          expand: true,
                          onPressed: onAdd,
                        ),
                      );
                    }
                    final q = drafts[index].data;
                    return ListTile(
                      key: drafts[index].uiKey,
                      selected: index == selected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06),
                      leading: Icon(
                        q.isComplete
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: q.isComplete
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text('Pregunta ${q.questionNumber}'),
                      subtitle: q.isComplete
                          ? null
                          : Text(
                              q.missingFields.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.warning),
                            ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: drafts.length > 1
                            ? 'Eliminar pregunta'
                            : 'El examen debe tener al menos una pregunta',
                        onPressed: drafts.length > 1
                            ? () => onDelete(index)
                            : null,
                      ),
                      onTap: () => onSelect(index),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _QuestionForm(
                      key: drafts[selected].uiKey,
                      question: drafts[selected].data,
                      onChanged: (q) => onChanged(selected, q),
                      onAddOption: () => onAddOption(selected),
                      onRemoveOption: (i) => onRemoveOption(selected, i),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileEditor extends StatefulWidget {
  const _MobileEditor({
    required this.drafts,
    required this.embedded,
    required this.onChanged,
    required this.onAdd,
    required this.onDelete,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onSave,
    required this.saving,
  });

  final List<_DraftQuestion> drafts;
  final bool embedded;
  final void Function(int, ExamQuestion) onChanged;
  final VoidCallback onAdd;
  final void Function(int) onDelete;
  final void Function(int) onAddOption;
  final void Function(int, int) onRemoveOption;
  final VoidCallback onSave;
  final bool saving;

  @override
  State<_MobileEditor> createState() => _MobileEditorState();
}

class _MobileEditorState extends State<_MobileEditor> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _MobileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index > widget.drafts.length - 1) {
      setState(() => _index = widget.drafts.length - 1);
    }
  }

  Future<void> _openJumpSheet() async {
    final target = await showAppSheet<int>(
      context,
      builder: (_) =>
          _QuestionJumpSheet(drafts: widget.drafts, onAdd: widget.onAdd),
    );
    if (target != null && mounted) setState(() => _index = target);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.drafts.length;
    final completed = widget.drafts.where((d) => d.data.isComplete).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${_index + 1} de $total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppStatusChip(
                label: '$completed/$total completas',
                kind: completed == total
                    ? AppStatusKind.success
                    : AppStatusKind.warning,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            children: [
              TextButton(
                onPressed: _openJumpSheet,
                child: const Text('Ver todas'),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: total > 1
                    ? 'Eliminar pregunta'
                    : 'El examen debe tener al menos una pregunta',
                onPressed: total > 1 ? () => widget.onDelete(_index) : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _QuestionForm(
              key: widget.drafts[_index].uiKey,
              question: widget.drafts[_index].data,
              onChanged: (q) => widget.onChanged(_index, q),
              onAddOption: () => widget.onAddOption(_index),
              onRemoveOption: (i) => widget.onRemoveOption(_index, i),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_index > 0)
                Expanded(
                  child: AppButton(
                    label: 'Anterior',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => setState(() => _index--),
                  ),
                ),
              if (_index > 0) const SizedBox(width: 8),
              if (_index < total - 1)
                Expanded(
                  child: AppButton(
                    label: 'Siguiente',
                    onPressed: () => setState(() => _index++),
                  ),
                ),
              if (_index == total - 1)
                Expanded(
                  child: AppButton(
                    label: widget.embedded ? 'Continuar a revisar' : 'Guardar',
                    isLoading: widget.saving,
                    onPressed: widget.onSave,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mobile-only "jump to a question" picker (§ pain point: the old stepper
/// had no overview of which questions still needed work). Deleting is left
/// to the per-question view's own delete icon — mixing a destructive action
/// into this static snapshot list would need it to stay reactive, which
/// isn't worth the complexity for a picker that's dismissed on selection.
class _QuestionJumpSheet extends StatelessWidget {
  const _QuestionJumpSheet({required this.drafts, required this.onAdd});

  final List<_DraftQuestion> drafts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Preguntas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final q = drafts[index].data;
                  return ListTile(
                    leading: Icon(
                      q.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: q.isComplete
                          ? AppColors.success
                          : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text('Pregunta ${q.questionNumber}'),
                    subtitle: q.isComplete
                        ? null
                        : Text(q.missingFields.join(', ')),
                    onTap: () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppButton(
                label: '+ Agregar pregunta',
                variant: AppButtonVariant.outlined,
                icon: Icons.add,
                expand: true,
                onPressed: () {
                  final newIndex = drafts.length;
                  onAdd();
                  Navigator.of(context).pop(newIndex);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  const _QuestionForm({
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
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
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

  // The form is now keyed by a stable `uiKey` (see `_DraftQuestion`), so
  // `initState` won't rerun just because an option was added/removed on the
  // SAME question — controllers have to be resynced here instead.
  @override
  void didUpdateWidget(covariant _QuestionForm oldWidget) {
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
