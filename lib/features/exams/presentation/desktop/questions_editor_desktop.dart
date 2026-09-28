import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../shared/question_form.dart';
import '../shared/questions_draft_controller.dart';

/// Desktop question bank editor: question list on the left, the selected
/// question's form on the right, for fast bulk entry.
class QuestionsEditorDesktop extends StatelessWidget {
  const QuestionsEditorDesktop({
    super.key,
    required this.controller,
    required this.embedded,
    required this.onSave,
  });

  final QuestionsDraftController controller;
  final bool embedded;

  /// "Guardar preguntas", or "Continuar a revisar" when [embedded] in the
  /// exam-creation wizard.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final drafts = controller.drafts;
    final selected = controller.selected;
    final saving = controller.saving;
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
                          onPressed: controller.addQuestion,
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
                            ? () => controller.removeQuestion(context, index)
                            : null,
                      ),
                      onTap: () => controller.select(index),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: QuestionForm(
                      key: drafts[selected].uiKey,
                      question: drafts[selected].data,
                      onChanged: (q) => controller.updateQuestion(selected, q),
                      onAddOption: () => controller.addOption(selected),
                      onRemoveOption: (i) =>
                          controller.removeOption(selected, i),
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
