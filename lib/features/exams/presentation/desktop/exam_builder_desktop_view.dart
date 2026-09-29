import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../shared/exam_builder_controller.dart';
import '../shared/exam_builder_sections.dart';
import 'questions_editor_desktop.dart';

/// Desktop wizard: page header, a clickable three-step indicator, and the
/// question bank as list + form.
class ExamBuilderDesktopView extends StatelessWidget {
  const ExamBuilderDesktopView({super.key, required this.controller});

  final ExamBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: 'Nuevo examen',
            breadcrumbs: const ['Exámenes', 'Nuevo examen'],
            onBack: () => Navigator.of(context).maybePop(),
          ),
          _StepIndicator(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: ExamBuilderSections(
              controller: controller,
              questionsEditor: (questions) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: QuestionsEditorDesktop(
                  controller: questions,
                  embedded: true,
                  onSave: () => controller.jumpTo(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.controller});

  final ExamBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: InkWell(
                onTap: controller.canJumpTo(i)
                    ? () => controller.jumpTo(i)
                    : null,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= controller.sectionIndex
                            ? AppColors.accentBlue
                            : colorScheme.surfaceContainerHighest,
                      ),
                      alignment: Alignment.center,
                      child: i < controller.sectionIndex
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: textTheme.labelMedium?.copyWith(
                                color: i == controller.sectionIndex
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      examBuilderSectionLabels[i],
                      style: i == controller.sectionIndex
                          ? textTheme.titleMedium?.copyWith(
                              color: AppColors.accentBlue,
                            )
                          : textTheme.bodyMedium?.copyWith(
                              color: controller.canJumpTo(i)
                                  ? null
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < 2)
              Expanded(
                child: Divider(
                  thickness: 2,
                  color: i < controller.sectionIndex
                      ? AppColors.accentBlue
                      : colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
