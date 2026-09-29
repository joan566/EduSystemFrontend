import '../../../../core/utils/formatters.dart';
import '../../domain/entities/exam_entity.dart';

class QuestionOptionModel {
  static QuestionOption fromJson(Map<String, dynamic> json) => QuestionOption(
    letter: json['letter'] as String,
    text: json['text'] as String,
  );

  static Map<String, dynamic> toJson(QuestionOption option) => {
    'letter': option.letter,
    'text': option.text,
  };
}

class ExamQuestionModel {
  static ExamQuestion fromJson(Map<String, dynamic> json) => ExamQuestion(
    questionNumber: json['questionNumber'] as int,
    statement: json['statement'] as String,
    correctOption: json['correctOption'] as String,
    points: (json['points'] as num?)?.toDouble(),
    options: (json['options'] as List<dynamic>)
        .map((e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static Map<String, dynamic> toJson(ExamQuestion question) => {
    'questionNumber': question.questionNumber,
    'statement': question.statement,
    'correctOption': question.correctOption,
    if (question.points != null) 'points': question.points,
    'options': question.options.map(QuestionOptionModel.toJson).toList(),
  };
}

class ExamSummaryModel {
  static ExamSummaryEntity fromJson(Map<String, dynamic> json) =>
      ExamSummaryEntity(
        id: json['id'] as int,
        evaluationId: json['evaluationId'] as int,
        teachingPeriodId: json['teachingPeriodId'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        evaluationDate: json['evaluationDate'] == null
            ? null
            : Formatters.parseApiDateTime(json['evaluationDate'] as String),
        maximumScore: (json['maximumScore'] as num?)?.toDouble(),
        numberOfQuestions: json['numberOfQuestions'] as int,
        ready: json['ready'] as bool? ?? false,
      );
}

class ExamModel {
  static ExamEntity fromJson(Map<String, dynamic> json) => ExamEntity(
    id: json['id'] as int,
    evaluationId: json['evaluationId'] as int,
    teachingPeriodId: json['teachingPeriodId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    evaluationDate: json['evaluationDate'] == null
        ? null
        : Formatters.parseApiDateTime(json['evaluationDate'] as String),
    maximumScore: (json['maximumScore'] as num?)?.toDouble(),
    numberOfQuestions: json['numberOfQuestions'] as int,
    ready: json['ready'] as bool? ?? false,
    optionCount: json['optionCount'] as int? ?? 4,
    questions: (json['questions'] as List<dynamic>? ?? const [])
        .map((e) => ExamQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static Map<String, dynamic> toCreateRequest({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    required int numberOfQuestions,
    List<ExamQuestion>? questions,
  }) => {
    'teachingPeriodId': teachingPeriodId,
    'name': name,
    if (description != null && description.isNotEmpty)
      'description': description,
    if (evaluationDate != null)
      'evaluationDate': Formatters.toApiDateTime(evaluationDate),
    if (maximumScore != null) 'maximumScore': maximumScore,
    'numberOfQuestions': numberOfQuestions,
    if (questions != null)
      'questions': questions.map(ExamQuestionModel.toJson).toList(),
  };

  static Map<String, dynamic> toUpdateRequest({
    required String name,
    String? description,
    DateTime? evaluationDate,
  }) => {
    'name': name,
    'description': description,
    if (evaluationDate != null)
      'evaluationDate': Formatters.toApiDateTime(evaluationDate),
  };
}
