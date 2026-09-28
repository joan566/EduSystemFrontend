import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import 'questions_draft_controller.dart';

const examBuilderSectionLabels = ['Información', 'Preguntas', 'Revisar'];

/// State of the create-exam wizard: Información (metadata) → Preguntas
/// (question drafts) → Revisar (preview + the one real save). Owned by the
/// page entry point, so the wizard survives a mobile <-> desktop switch;
/// each view only decides how the steps and sections are laid out.
class ExamBuilderController extends ChangeNotifier {
  ExamBuilderController({required this.teachingPeriodId});

  final int teachingPeriodId;

  final infoFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final maxScoreController = TextEditingController();

  int _sectionIndex = 0;
  int get sectionIndex => _sectionIndex;

  ExamEntity? _exam;
  ExamEntity? get exam => _exam;

  /// Created with the exam (after step 1); drives the Preguntas step.
  QuestionsDraftController? _questions;
  QuestionsDraftController? get questions => _questions;

  List<ExamQuestion> _drafts = [];
  List<ExamQuestion> get drafts => _drafts;

  DateTime? _evaluationDate;
  DateTime? get evaluationDate => _evaluationDate;

  bool _savingInfo = false;
  bool get savingInfo => _savingInfo;

  bool _savingExam = false;
  bool get savingExam => _savingExam;

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  bool canJumpTo(int index) => index == 0 || _exam != null;

  void jumpTo(int index) {
    if (canJumpTo(index)) _update(() => _sectionIndex = index);
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    _update(() {
      _evaluationDate = time == null
          ? date
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> continueFromInfo(BuildContext context) async {
    if (!infoFormKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final maximumScore = double.tryParse(maxScoreController.text.trim());
    final provider = context.read<ExamsProvider>();

    _update(() => _savingInfo = true);
    final current = _exam;
    if (current == null) {
      final exam = await provider.create(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description.isEmpty ? null : description,
        evaluationDate: _evaluationDate,
        maximumScore: maximumScore,
        // Seed value only — the Preguntas step lets the user add/remove
        // questions freely from here on; the real count is whatever's in
        // the array sent to PUT /exams/{id}/questions when saving.
        numberOfQuestions: 1,
      );
      _update(() => _savingInfo = false);
      if (exam == null) {
        final error = provider.lastError;
        if (error != null && context.mounted) context.showApiError(error);
        return;
      }
      _update(() {
        _exam = exam;
        _questions = QuestionsDraftController(
          exam,
          onDraftsChanged: (drafts) => _drafts = drafts,
        );
        _sectionIndex = 1;
      });
    } else {
      final changed =
          name != current.name ||
          description != (current.description ?? '') ||
          _evaluationDate != current.evaluationDate;
      if (changed) {
        final error = await provider.updateMetadata(
          current.id,
          name: name,
          description: description,
          evaluationDate: _evaluationDate,
        );
        if (error != null) {
          _update(() => _savingInfo = false);
          if (context.mounted) context.showApiError(error);
          return;
        }
      }
      _update(() {
        _savingInfo = false;
        _sectionIndex = 1;
      });
    }
  }

  Future<void> saveExam(BuildContext context) async {
    final exam = _exam;
    if (exam == null) return;
    _update(() => _savingExam = true);
    final error = await context.read<ExamsProvider>().saveQuestions(
      exam.id,
      _drafts,
    );
    _update(() => _savingExam = false);
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Examen guardado correctamente.');
      context.pushReplacement(RoutePaths.examDetail(exam.id));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _questions?.dispose();
    nameController.dispose();
    descriptionController.dispose();
    maxScoreController.dispose();
    super.dispose();
  }
}
