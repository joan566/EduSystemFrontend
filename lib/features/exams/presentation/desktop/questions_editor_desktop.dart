import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../shared/questions_draft_controller.dart';
import 'widgets/question_editor_panel.dart';
import 'widgets/question_navigator.dart';

/// Desktop question bank editor: a navigator of every question on the
/// left, the selected question's editor on the right, a toolbar with
/// progress and save, and keyboard shortcuts (Ctrl+S, Alt+↑/↓) for fast
/// bulk entry.
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

  static const _navigatorWidth = 300.0;

  void _move(int delta) => controller.select(controller.selected + delta);

  @override
  Widget build(BuildContext context) {
    final drafts = controller.drafts;
    final selected = controller.selected;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): onSave,
        const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
            _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
            _move(1),
      },
      child: Focus(
        // In the wizard every step stays mounted (IndexedStack), so taking
        // focus there would steal it from the visible step.
        autofocus: !embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              controller: controller,
              embedded: embedded,
              onSave: onSave,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _navigatorWidth,
                    child: QuestionNavigator(
                      drafts: drafts,
                      selected: selected,
                      onSelect: controller.select,
                      onAdd: controller.addQuestion,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: QuestionEditorPanel(
                      key: drafts[selected].uiKey,
                      question: drafts[selected].data,
                      total: drafts.length,
                      onChanged: (q) => controller.updateQuestion(selected, q),
                      onAddOption: () => controller.addOption(selected),
                      onRemoveOption: (i) =>
                          controller.removeOption(selected, i),
                      onPrevious: selected > 0 ? () => _move(-1) : null,
                      onNext: selected < drafts.length - 1
                          ? () => _move(1)
                          : null,
                      onDelete: drafts.length > 1
                          ? () => controller.removeQuestion(context, selected)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.embedded,
    required this.onSave,
  });

  final QuestionsDraftController controller;
  final bool embedded;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final drafts = controller.drafts;
    final completed = drafts.where((d) => d.data.isComplete).length;
    final allDone = completed == drafts.length;

    // The shortcut hint and the extra add button only when there's room.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed de ${drafts.length} completas',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: drafts.isEmpty ? 0 : completed / drafts.length,
                    minHeight: 6,
                    color: allDone ? AppColors.success : AppColors.accentBlue,
                    backgroundColor: AppColors.accentBlue.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: controller.dirty && !embedded
                ? Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Cambios sin guardar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          if (constraints.maxWidth >= 1100) ...[
            Text(
              'Alt+↑/↓ cambiar de pregunta  ·  Ctrl+S '
              '${embedded ? 'continuar' : 'guardar'}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // The navigator has its own "Agregar pregunta" at the bottom;
          // this one is a shortcut when there's room.
          if (constraints.maxWidth >= 840) ...[
            AppButton(
              label: 'Agregar pregunta',
              icon: Icons.add,
              variant: AppButtonVariant.outlined,
              onPressed: controller.addQuestion,
            ),
            const SizedBox(width: 10),
          ],
          AppButton(
            label: embedded ? 'Continuar a revisar' : 'Guardar preguntas',
            icon: embedded ? Icons.arrow_forward : Icons.save_outlined,
            isLoading: controller.saving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
