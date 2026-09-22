import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';
import '../widgets/exam_info_section.dart';
import '../widgets/exam_review_section.dart';
import '../widgets/questions_editor.dart';

const _sectionLabels = ['Información', 'Preguntas', 'Revisar'];

/// Single-screen replacement for the old "small metadata dialog, then jump
/// to a whole different tabbed detail page" create-exam flow. Información
/// (exam metadata) → Preguntas (add/edit/remove questions) → Revisar
/// (read-only preview + the one real save action) are shown via an
/// [IndexedStack] driven by [_sectionIndex] — not a `Stepper`/`PageView`
/// (neither exists anywhere else in this app; this mirrors the same
/// simple-int-index idiom `QuestionsEditor`'s mobile stepper already uses).
///
/// Keeping every section mounted (via [IndexedStack] instead of a
/// destructive widget switch) is what lets the Preguntas section's draft
/// list survive a trip to Revisar and back with no extra state plumbing.
class ExamBuilderPage extends StatefulWidget {
  const ExamBuilderPage({super.key, required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  State<ExamBuilderPage> createState() => _ExamBuilderPageState();
}

class _ExamBuilderPageState extends State<ExamBuilderPage> {
  int _sectionIndex = 0;
  ExamEntity? _exam;
  List<ExamQuestion> _drafts = [];

  final _infoFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  DateTime? _evaluationDate;

  bool _savingInfo = false;
  bool _savingExam = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    setState(() {
      _evaluationDate = time == null
          ? date
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _handleInfoContinue() async {
    if (!_infoFormKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final maximumScore = double.tryParse(_maxScoreController.text.trim());

    setState(() => _savingInfo = true);
    if (_exam == null) {
      final exam = await context.read<ExamsProvider>().create(
        teachingPeriodId: widget.teachingPeriodId,
        name: name,
        description: description.isEmpty ? null : description,
        evaluationDate: _evaluationDate,
        maximumScore: maximumScore,
        // Seed value only — the Preguntas step lets the user add/remove
        // questions freely from here on; the real count is whatever's in
        // the array sent to PUT /exams/{id}/questions when saving.
        numberOfQuestions: 1,
      );
      if (!mounted) return;
      setState(() => _savingInfo = false);
      if (exam == null) {
        final error = context.read<ExamsProvider>().lastError;
        if (error != null) context.showApiError(error);
        return;
      }
      setState(() {
        _exam = exam;
        _sectionIndex = 1;
      });
    } else {
      final changed =
          name != _exam!.name ||
          description != (_exam!.description ?? '') ||
          _evaluationDate != _exam!.evaluationDate;
      if (changed) {
        final error = await context.read<ExamsProvider>().updateMetadata(
          _exam!.id,
          name: name,
          description: description,
          evaluationDate: _evaluationDate,
        );
        if (!mounted) return;
        if (error != null) {
          setState(() => _savingInfo = false);
          context.showApiError(error);
          return;
        }
      }
      setState(() {
        _savingInfo = false;
        _sectionIndex = 1;
      });
    }
  }

  Future<void> _handleFinalSave() async {
    if (_exam == null) return;
    setState(() => _savingExam = true);
    final error = await context.read<ExamsProvider>().saveQuestions(
      _exam!.id,
      _drafts,
    );
    if (!mounted) return;
    setState(() => _savingExam = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Examen guardado correctamente.');
      context.pushReplacement(RoutePaths.examDetail(_exam!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo examen')),
      body: Column(
        children: [
          _BuilderStepIndicator(
            sectionIndex: _sectionIndex,
            canJumpToReview: _exam != null,
            onJump: _jumpTo,
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _sectionIndex,
              children: [
                ExamInfoSection(
                  formKey: _infoFormKey,
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                  maxScoreController: _maxScoreController,
                  evaluationDate: _evaluationDate,
                  onPickDate: _pickDate,
                  saving: _savingInfo,
                  onContinue: _handleInfoContinue,
                ),
                _exam == null
                    ? const AppLoading()
                    : QuestionsEditor(
                        examId: _exam!.id,
                        exam: _exam!,
                        embedded: true,
                        onDraftsChanged: (drafts) => _drafts = drafts,
                        onContinue: () => setState(() => _sectionIndex = 2),
                      ),
                ExamReviewSection(
                  name: _nameController.text,
                  description: _descriptionController.text,
                  evaluationDate: _evaluationDate,
                  maximumScore: double.tryParse(
                    _maxScoreController.text.trim(),
                  ),
                  questions: _drafts,
                  saving: _savingExam,
                  onEdit: () => setState(() => _sectionIndex = 1),
                  onSave: _handleFinalSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _jumpTo(int index) {
    if (index == 0 || _exam != null) setState(() => _sectionIndex = index);
  }
}

class _BuilderStepIndicator extends StatelessWidget {
  const _BuilderStepIndicator({
    required this.sectionIndex,
    required this.canJumpToReview,
    required this.onJump,
  });

  final int sectionIndex;
  final bool canJumpToReview;
  final ValueChanged<int> onJump;

  bool _canJump(int index) => index != 2 || canJumpToReview;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso ${sectionIndex + 1} de 3 · ${_sectionLabels[sectionIndex]}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            AppProgressBar(value: (sectionIndex + 1) / 3),
          ],
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: InkWell(
                onTap: _canJump(i) ? () => onJump(i) : null,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= sectionIndex
                            ? AppColors.primary
                            : colorScheme.surfaceContainerHighest,
                      ),
                      alignment: Alignment.center,
                      child: i < sectionIndex
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: textTheme.labelMedium?.copyWith(
                                color: i == sectionIndex
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _sectionLabels[i],
                      style: i == sectionIndex
                          ? textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                            )
                          : textTheme.bodyMedium?.copyWith(
                              color: _canJump(i)
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
                  color: i < sectionIndex
                      ? AppColors.primary
                      : colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
