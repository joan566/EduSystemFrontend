class GradingScaleEntity {
  const GradingScaleEntity({
    required this.id,
    required this.name,
    required this.minimumValue,
    required this.maximumValue,
  });

  final int id;
  final String name;
  final double minimumValue;
  final double maximumValue;
}

class EvaluationCategoryEntity {
  const EvaluationCategoryEntity({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
}

class CategoryWeight {
  const CategoryWeight({
    required this.evaluationCategoryId,
    required this.weight,
  });

  final int evaluationCategoryId;
  final double weight;
}

class GradingConfigurationEntity {
  const GradingConfigurationEntity({
    required this.id,
    required this.teachingPeriodId,
    required this.scale,
    required this.weights,
    required this.totalWeight,
    required this.complete,
    this.passingGrade,
  });

  final int id;
  final int teachingPeriodId;
  final GradingScaleEntity scale;
  final List<CategoryWeight> weights;
  final double totalWeight;
  final bool complete;

  /// Minimum period grade to pass; null when the class doesn't define one.
  final double? passingGrade;
}

class CategoryGrade {
  const CategoryGrade({
    required this.categoryId,
    required this.categoryName,
    required this.weight,
    this.achievement,
    this.gradeOnScale,
    required this.evaluationCount,
  });

  final int categoryId;
  final String categoryName;
  final double weight;
  final double? achievement;
  final double? gradeOnScale;
  final int evaluationCount;
}

class StudentPeriodGrade {
  const StudentPeriodGrade({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.categories,
    this.periodGrade,
    this.passing,
  });

  final int studentId;
  final String studentCode;
  final String studentName;
  final List<CategoryGrade> categories;
  final double? periodGrade;

  /// Against the class's passing grade; null when it has none.
  final bool? passing;
}

class PeriodGradesEntity {
  const PeriodGradesEntity({
    required this.teachingPeriodId,
    required this.scale,
    required this.students,
    this.passingGrade,
  });

  final int teachingPeriodId;
  final GradingScaleEntity scale;
  final List<StudentPeriodGrade> students;
  final double? passingGrade;
}
