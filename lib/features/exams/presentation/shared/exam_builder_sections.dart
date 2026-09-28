import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_loading.dart';
import 'exam_builder_controller.dart';
import 'exam_info_section.dart';
import 'exam_review_section.dart';
import 'questions_draft_controller.dart';

/// The wizard's three sections kept mounted in an [IndexedStack], so the
/// Preguntas drafts survive a trip to Revisar and back. [questionsEditor]
/// is the current platform's question editor.
class ExamBuilderSections extends StatelessWidget {
  const ExamBuilderSections({
    super.key,
    required this.controller,
    required this.questionsEditor,
  });

  final ExamBuilderController controller;
  final Widget Function(QuestionsDraftController questions) questionsEditor;

  @override
  Widget build(BuildContext context) {
    final questions = controller.questions;
    return IndexedStack(
      index: controller.sectionIndex,
      children: [
        ExamInfoSection(
          formKey: controller.infoFormKey,
          nameController: controller.nameController,
          descriptionController: controller.descriptionController,
          maxScoreController: controller.maxScoreController,
          evaluationDate: controller.evaluationDate,
          onPickDate: () => controller.pickDate(context),
          saving: controller.savingInfo,
          onContinue: () => controller.continueFromInfo(context),
        ),
        questions == null
            ? const AppLoading()
            : ListenableBuilder(
                listenable: questions,
                builder: (_, _) => questionsEditor(questions),
              ),
        ExamReviewSection(
          name: controller.nameController.text,
          description: controller.descriptionController.text,
          evaluationDate: controller.evaluationDate,
          maximumScore: double.tryParse(
            controller.maxScoreController.text.trim(),
          ),
          questions: controller.drafts,
          saving: controller.savingExam,
          onEdit: () => controller.jumpTo(1),
          onSave: () => controller.saveExam(context),
        ),
      ],
    );
  }
}
