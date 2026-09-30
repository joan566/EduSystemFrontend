import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../domain/entities/exam_entity.dart';
import '../shared/questions_draft_controller.dart';

/// Mobile question bank editor: every question as an editable card in one
/// scrolling list, "Agregar pregunta" at the end, and the save button
/// pinned below.
/// Placeholder of [QuestionsEditorMobile] while an exam's questions load:
/// the count line and question cards with their statement and options.
class QuestionsEditorMobileSkeleton extends StatelessWidget {
  const QuestionsEditorMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Skeleton(
      child: SkeletonFill(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonText(style: textTheme.bodySmall, width: 150),
            const SizedBox(height: 10),
            SkeletonRepeat(
              count: 3,
              spacing: 12,
              builder: (context, i) => SkeletonSurface(
                radius: 14,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SkeletonText(style: textTheme.titleMedium, width: 96),
                        const SizedBox(width: 10),
                        const SkeletonBox(width: 70, height: 20, radius: 10),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SkeletonBox(height: 48, radius: 8),
                    const SizedBox(height: 12),
                    for (var o = 0; o < 4; o++) ...[
                      if (o > 0) const SizedBox(height: 8),
                      const Row(
                        children: [
                          SkeletonCircle(size: 20),
                          SizedBox(width: 10),
                          Expanded(child: SkeletonBox(height: 36, radius: 8)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionsEditorMobile extends StatefulWidget {
  const QuestionsEditorMobile({
    super.key,
    required this.controller,
    required this.embedded,
    required this.onSave,
  });

  final QuestionsDraftController controller;
  final bool embedded;

  /// "Guardar cambios", or "Continuar a revisar" when [embedded] in the
  /// exam-creation wizard.
  final VoidCallback onSave;

  @override
  State<QuestionsEditorMobile> createState() => _QuestionsEditorMobileState();
}

class _QuestionsEditorMobileState extends State<QuestionsEditorMobile> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _addQuestion() {
    widget.controller.addQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final drafts = controller.drafts;
    final completed = drafts.where((d) => d.data.isComplete).length;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10),
                child: Text(
                  '${drafts.length} preguntas  ·  $completed completas',
                  style: textTheme.bodySmall?.copyWith(
                    color: completed == drafts.length
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              for (var i = 0; i < drafts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(
                    key: drafts[i].uiKey,
                    question: drafts[i].data,
                    canDelete: drafts.length > 1,
                    onChanged: (q) => controller.updateQuestion(i, q),
                    onDelete: () => controller.removeQuestion(context, i),
                    onAddOption: () => controller.addOption(i),
                    onRemoveOption: (o) => controller.removeOption(i, o),
                  ),
                ),
              AppButton(
                label: 'Agregar pregunta',
                icon: Icons.add,
                variant: AppButtonVariant.outlined,
                expand: true,
                onPressed: _addQuestion,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppButton(
              label: widget.embedded
                  ? 'Continuar a revisar'
                  : 'Guardar cambios',
              isLoading: controller.saving,
              expand: true,
              onPressed: widget.onSave,
            ),
          ),
        ),
      ],
    );
  }
}

/// One question: statement, options (tap the radio to mark the correct
/// one), "Agregar opción" and optional points.
class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  final ExamQuestion question;
  final bool canDelete;
  final ValueChanged<ExamQuestion> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
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

  // The card is keyed by the draft's stable `uiKey`, so adding/removing an
  // option (which relabels the rest) arrives here, not in `initState`.
  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
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
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
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
              Text(
                'Pregunta ${q.questionNumber}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(width: 10),
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
                tooltip: widget.canDelete
                    ? 'Eliminar pregunta'
                    : 'El examen debe tener al menos una pregunta',
                onPressed: widget.canDelete ? widget.onDelete : null,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _statement,
                minLines: 2,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: textTheme.bodyMedium,
                decoration: _bare('Escribe el enunciado de la pregunta'),
                onChanged: (_) => _emit(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 6),
              child: _OptionRow(
                letter: q.options[i].letter,
                controller: _options[i],
                correct: q.correctOption == q.options[i].letter,
                canRemove: q.options.length > 2,
                onMarkCorrect: () => _emit(correctOption: q.options[i].letter),
                onChanged: _emit,
                onRemove: () => widget.onRemoveOption(i),
              ),
            ),
          const SizedBox(height: 2),
          // Wraps so the points field drops below the button on narrow
          // phones or with large text.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Agregar opción',
                icon: Icons.add,
                variant: AppButtonVariant.outlined,
                onPressed: widget.onAddOption,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Puntos', style: textTheme.bodySmall),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _points,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Auto',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
          if (!q.isComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Falta: ${q.missingFields.join(', ').toLowerCase()}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: correct ? AppColors.successBg : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: correct
              ? AppColors.success.withValues(alpha: 0.4)
              : colors.outline,
        ),
      ),
      child: Row(
        children: [
          // Radio + letter form one tap target for "this is the answer".
          InkWell(
            onTap: onMarkCorrect,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Semantics(
              button: true,
              selected: correct,
              label: 'Marcar la opción $letter como correcta',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(
                      correct
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: correct ? AppColors.success : colors.outline,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 14,
                      child: Text(
                        letter,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: correct ? AppColors.success : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: textTheme.bodyMedium,
              decoration: _bare('Texto de la opción $letter'),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (correct)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Correcta',
                style: textTheme.labelSmall?.copyWith(color: AppColors.success),
              ),
            ),
          if (canRemove)
            IconButton(
              tooltip: 'Quitar opción',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

/// A text field without its own chrome, for inputs that sit inside a
/// styled box.
InputDecoration _bare(String hint) => InputDecoration(
  hintText: hint,
  isDense: true,
  filled: false,
  contentPadding: const EdgeInsets.symmetric(vertical: 10),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
);
