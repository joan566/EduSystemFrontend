class QuestionOption {
  const QuestionOption({required this.letter, required this.text});

  final String letter;
  final String text;
}

class ExamQuestion {
  const ExamQuestion({
    required this.questionNumber,
    required this.statement,
    required this.correctOption,
    this.points,
    required this.options,
  });

  final int questionNumber;
  final String statement;
  final String correctOption;
  final double? points;
  final List<QuestionOption> options;

  bool get isComplete =>
      statement.trim().isNotEmpty &&
      correctOption.trim().isNotEmpty &&
      options.length >= 2 &&
      options.every((o) => o.text.trim().isNotEmpty);

  /// Specific, human-readable list of what's missing — used to replace the
  /// single incomplete/complete icon with an actual message (e.g. in the
  /// desktop rail's subtitle or the mobile jump sheet), instead of leaving
  /// the user to guess which part of the question needs attention.
  List<String> get missingFields {
    final missing = <String>[];
    if (statement.trim().isEmpty) missing.add('Enunciado');
    if (options.length < 2 || options.any((o) => o.text.trim().isEmpty)) {
      missing.add('Texto de las opciones');
    }
    if (correctOption.trim().isEmpty) missing.add('Respuesta correcta');
    return missing;
  }

  ExamQuestion copyWith({
    int? questionNumber,
    String? statement,
    String? correctOption,
    double? points,
    List<QuestionOption>? options,
  }) => ExamQuestion(
    questionNumber: questionNumber ?? this.questionNumber,
    statement: statement ?? this.statement,
    correctOption: correctOption ?? this.correctOption,
    points: points ?? this.points,
    options: options ?? this.options,
  );
}

/// Lightweight listing shape — `GET /exams` (§35 summary, no questions).
class ExamSummaryEntity {
  const ExamSummaryEntity({
    required this.id,
    required this.evaluationId,
    required this.teachingPeriodId,
    required this.name,
    this.description,
    this.evaluationDate,
    this.maximumScore,
    required this.numberOfQuestions,
  });

  final int id;
  final int evaluationId;
  final int teachingPeriodId;
  final String name;
  final String? description;
  final DateTime? evaluationDate;
  final double? maximumScore;
  final int numberOfQuestions;
}

/// Full detail — `GET /exams/{id}`, includes questions and correct answers.
class ExamEntity extends ExamSummaryEntity {
  const ExamEntity({
    required super.id,
    required super.evaluationId,
    required super.teachingPeriodId,
    required super.name,
    super.description,
    super.evaluationDate,
    super.maximumScore,
    required super.numberOfQuestions,
    required this.ready,
    required this.optionCount,
    required this.questions,
  });

  final bool ready;
  final int optionCount;
  final List<ExamQuestion> questions;
}
