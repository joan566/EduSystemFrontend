import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../shared/question_form.dart';
import '../shared/questions_draft_controller.dart';

/// Mobile question bank editor: a full-screen one-question-at-a-time
/// stepper with a "jump to question" sheet.
class QuestionsEditorMobile extends StatefulWidget {
  const QuestionsEditorMobile({
    super.key,
    required this.controller,
    required this.embedded,
    required this.onSave,
  });

  final QuestionsDraftController controller;
  final bool embedded;

  /// "Guardar", or "Continuar a revisar" when [embedded] in the
  /// exam-creation wizard.
  final VoidCallback onSave;

  @override
  State<QuestionsEditorMobile> createState() => _QuestionsEditorMobileState();
}

class _QuestionsEditorMobileState extends State<QuestionsEditorMobile> {
  Future<void> _openJumpSheet() async {
    final target = await showMobileSheet<int>(
      context,
      builder: (_) => _QuestionJumpSheet(
        drafts: widget.controller.drafts,
        onAdd: widget.controller.addQuestion,
      ),
    );
    if (target != null && mounted) widget.controller.select(target);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final drafts = controller.drafts;
    final index = controller.selected;
    final total = drafts.length;
    final completed = drafts.where((d) => d.data.isComplete).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${index + 1} de $total',
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
                onPressed: total > 1
                    ? () => controller.removeQuestion(context, index)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuestionForm(
              key: drafts[index].uiKey,
              question: drafts[index].data,
              onChanged: (q) => controller.updateQuestion(index, q),
              onAddOption: () => controller.addOption(index),
              onRemoveOption: (i) => controller.removeOption(index, i),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: AppButton(
                    label: 'Anterior',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => controller.select(index - 1),
                  ),
                ),
              if (index > 0) const SizedBox(width: 8),
              if (index < total - 1)
                Expanded(
                  child: AppButton(
                    label: 'Siguiente',
                    onPressed: () => controller.select(index + 1),
                  ),
                ),
              if (index == total - 1)
                Expanded(
                  child: AppButton(
                    label: widget.embedded ? 'Continuar a revisar' : 'Guardar',
                    isLoading: controller.saving,
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

  final List<DraftQuestion> drafts;
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
