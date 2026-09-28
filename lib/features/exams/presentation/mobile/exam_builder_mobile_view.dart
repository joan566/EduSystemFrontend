import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_loading.dart';
import '../shared/exam_builder_controller.dart';
import '../shared/exam_builder_sections.dart';
import 'questions_editor_mobile.dart';

/// Mobile wizard: app bar, a compact "Paso N de 3" progress bar, and the
/// one-question-at-a-time editor.
class ExamBuilderMobileView extends StatelessWidget {
  const ExamBuilderMobileView({super.key, required this.controller});

  final ExamBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final index = controller.sectionIndex;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo examen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paso ${index + 1} de 3 · ${examBuilderSectionLabels[index]}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                AppProgressBar(value: (index + 1) / 3),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ExamBuilderSections(
              controller: controller,
              questionsEditor: (questions) => QuestionsEditorMobile(
                controller: questions,
                embedded: true,
                onSave: () => controller.jumpTo(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
