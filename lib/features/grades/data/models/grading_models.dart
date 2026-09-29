import '../../domain/entities/grading_entities.dart';

class GradingScaleModel {
  static GradingScaleEntity fromJson(Map<String, dynamic> json) =>
      GradingScaleEntity(
        id: json['id'] as int,
        name: json['name'] as String,
        minimumValue: (json['minimumValue'] as num).toDouble(),
        maximumValue: (json['maximumValue'] as num).toDouble(),
      );
}

class EvaluationCategoryModel {
  static EvaluationCategoryEntity fromJson(Map<String, dynamic> json) =>
      EvaluationCategoryEntity(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}

class GradingConfigurationModel {
  static GradingConfigurationEntity fromJson(Map<String, dynamic> json) =>
      GradingConfigurationEntity(
        id: json['id'] as int,
        teachingPeriodId: json['teachingPeriodId'] as int,
        scale: GradingScaleModel.fromJson(
          json['scale'] as Map<String, dynamic>,
        ),
        weights: (json['weights'] as List<dynamic>)
            .map(
              (e) => CategoryWeight(
                evaluationCategoryId:
                    (e as Map<String, dynamic>)['evaluationCategoryId'] as int,
                weight: (e['weight'] as num).toDouble(),
              ),
            )
            .toList(),
        totalWeight: (json['totalWeight'] as num).toDouble(),
        complete: json['complete'] as bool,
        passingGrade: (json['passingGrade'] as num?)?.toDouble(),
      );
}

class PeriodGradesModel {
  static PeriodGradesEntity fromJson(Map<String, dynamic> json) =>
      PeriodGradesEntity(
        teachingPeriodId: json['teachingPeriodId'] as int,
        scale: GradingScaleModel.fromJson(
          json['scale'] as Map<String, dynamic>,
        ),
        passingGrade: (json['passingGrade'] as num?)?.toDouble(),
        students: (json['students'] as List<dynamic>)
            .map((e) => _studentFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static StudentPeriodGrade _studentFromJson(Map<String, dynamic> json) =>
      StudentPeriodGrade(
        studentId: json['studentId'] as int,
        studentCode: json['studentCode'] as String,
        studentName: json['studentName'] as String,
        periodGrade: (json['periodGrade'] as num?)?.toDouble(),
        passing: json['passing'] as bool?,
        categories: (json['categories'] as List<dynamic>)
            .map((e) => _categoryFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static CategoryGrade categoryFromJson(Map<String, dynamic> json) =>
      _categoryFromJson(json);

  static CategoryGrade _categoryFromJson(Map<String, dynamic> json) =>
      CategoryGrade(
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String,
        weight: (json['weight'] as num).toDouble(),
        achievement: (json['achievement'] as num?)?.toDouble(),
        gradeOnScale: (json['gradeOnScale'] as num?)?.toDouble(),
        evaluationCount: json['evaluationCount'] as int,
      );
}
