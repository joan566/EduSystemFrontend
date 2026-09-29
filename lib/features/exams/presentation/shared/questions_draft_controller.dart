import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
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
class DraftQuestion {
  DraftQuestion({required this.uiKey, required this.data});

  final Key uiKey;
  final ExamQuestion data;
}

/// Question bank draft for one exam: the edited questions, which one is
/// selected, and saving. Rendered by `QuestionsEditorMobile` (card list) or
/// `QuestionsEditorDesktop` (list + form); owned by the page entry point so
/// drafts and the current question survive a mobile <-> desktop switch.
///
/// [onDraftsChanged] is used by the exam-creation wizard, whose Review step
/// does the real save, so it always has the latest drafts. Without it, the
/// editor saves via [save] (a full replace, per the API).
class QuestionsDraftController extends ChangeNotifier {
  QuestionsDraftController(ExamEntity exam, {this.onDraftsChanged}) {
    final seed = exam.questions.isNotEmpty
        ? exam.questions
        : [
            for (var i = 1; i <= exam.numberOfQuestions; i++)
              _blankQuestion(i, exam.optionCount),
          ];
    _optionCount = exam.optionCount;
    _drafts = [
      for (final q in seed) DraftQuestion(uiKey: UniqueKey(), data: q),
    ];
    if (onDraftsChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportDrafts();
        _dirty = false;
      });
    }
  }

  final ValueChanged<List<ExamQuestion>>? onDraftsChanged;
  late final int _optionCount;
  late List<DraftQuestion> _drafts;
  bool _disposed = false;

  List<DraftQuestion> get drafts => _drafts;

  int _selected = 0;
  int get selected => _selected;

  bool _saving = false;
  bool get saving => _saving;

  /// Drafts changed since load or the last successful save.
  bool _dirty = false;
  bool get dirty => _dirty;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _reportDrafts() {
    _dirty = true;
    onDraftsChanged?.call([for (final d in _drafts) d.data]);
  }

  List<DraftQuestion> _renumber(List<DraftQuestion> drafts) => [
    for (var i = 0; i < drafts.length; i++)
      DraftQuestion(
        uiKey: drafts[i].uiKey,
        data: drafts[i].data.copyWith(questionNumber: i + 1),
      ),
  ];

  void select(int index) {
    _selected = index.clamp(0, _drafts.length - 1);
    _notify();
  }

  void updateQuestion(int index, ExamQuestion updated) {
    _drafts[index] = DraftQuestion(uiKey: _drafts[index].uiKey, data: updated);
    _notify();
    _reportDrafts();
  }

  /// Appends a blank question and selects it.
  void addQuestion() {
    _drafts = _renumber([
      ..._drafts,
      DraftQuestion(
        uiKey: UniqueKey(),
        data: _blankQuestion(_drafts.length + 1, _optionCount),
      ),
    ]);
    _selected = _drafts.length - 1;
    _notify();
    _reportDrafts();
  }

  Future<void> removeQuestion(BuildContext context, int index) async {
    if (_drafts.length <= 1) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar pregunta',
      message:
          'Se perderá el contenido de esta pregunta. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || _disposed) return;
    _drafts = _renumber([..._drafts]..removeAt(index));
    _selected = _selected.clamp(0, _drafts.length - 1);
    _notify();
    _reportDrafts();
  }

  void addOption(int questionIndex) {
    final q = _drafts[questionIndex].data;
    updateQuestion(
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
  void removeOption(int questionIndex, int optionIndex) {
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
    updateQuestion(
      questionIndex,
      q.copyWith(options: relabeled, correctOption: newCorrectOption),
    );
  }

  Future<void> save(BuildContext context, int examId) async {
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
      if (!proceed || !context.mounted) return;
    }
    _saving = true;
    _notify();
    final error = await context.read<ExamsProvider>().saveQuestions(examId, [
      for (final d in _drafts) d.data,
    ]);
    _saving = false;
    if (error == null) _dirty = false;
    _notify();
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Preguntas guardadas.');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
