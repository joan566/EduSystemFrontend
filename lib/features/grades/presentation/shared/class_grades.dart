import '../../../teaching/presentation/shared/class_lookup.dart';
import '../../domain/entities/grading_entities.dart';

enum GradeStatusFilter { all, passing, failing, ungraded }

String gradeStatusFilterLabel(GradeStatusFilter f) => switch (f) {
  GradeStatusFilter.all => 'Todos',
  GradeStatusFilter.passing => 'Aprobados',
  GradeStatusFilter.failing => 'Reprobados',
  GradeStatusFilter.ungraded => 'Sin nota',
};

enum GradeSort { name, highest, lowest }

String gradeSortLabel(GradeSort s) => switch (s) {
  GradeSort.name => 'Nombre (A–Z)',
  GradeSort.highest => 'Nota más alta',
  GradeSort.lowest => 'Nota más baja',
};

/// Search, status and order over a class's period grades. Owned by the
/// page entry point so it survives a layout switch.
class GradesListFilters {
  const GradesListFilters({
    this.search = '',
    this.status = GradeStatusFilter.all,
    this.sort = GradeSort.name,
  });

  final String search;
  final GradeStatusFilter status;
  final GradeSort sort;

  GradesListFilters copyWith({
    String? search,
    GradeStatusFilter? status,
    GradeSort? sort,
  }) => GradesListFilters(
    search: search ?? this.search,
    status: status ?? this.status,
    sort: sort ?? this.sort,
  );

  List<StudentPeriodGrade> apply(List<StudentPeriodGrade> students) {
    final result = students
        .where(
          (s) => switch (status) {
            GradeStatusFilter.all => true,
            GradeStatusFilter.passing => s.passing == true,
            GradeStatusFilter.failing => s.passing == false,
            GradeStatusFilter.ungraded => s.periodGrade == null,
          },
        )
        .where((s) => matchesSearch(search, [s.studentName, s.studentCode]))
        .toList();
    int byGrade(StudentPeriodGrade a, StudentPeriodGrade b) =>
        (a.periodGrade ?? -1).compareTo(b.periodGrade ?? -1);
    switch (sort) {
      case GradeSort.name:
        result.sort((a, b) => a.studentName.compareTo(b.studentName));
      case GradeSort.highest:
        result.sort((a, b) => byGrade(b, a));
      case GradeSort.lowest:
        result.sort(byGrade);
    }
    return result;
  }
}

/// One bin of the grade distribution: grades in [from, to) (the last bin
/// includes [to]).
class GradeBin {
  const GradeBin({required this.from, required this.to, required this.count});

  final double from;
  final double to;
  final int count;
}

class CategoryAverage {
  const CategoryAverage({
    required this.name,
    required this.weight,
    required this.average,
  });

  final String name;
  final double weight;

  /// Mean grade on the scale; null when nobody has one.
  final double? average;
}

/// A class's period grades at a glance ("Resumen de la clase").
class ClassGradesSummary {
  ClassGradesSummary._({
    required this.students,
    required this.graded,
    required this.passing,
    required this.failing,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.bins,
    required this.categories,
  });

  factory ClassGradesSummary.from(PeriodGradesEntity data, {int binCount = 5}) {
    final grades = [
      for (final s in data.students)
        if (s.periodGrade != null) s.periodGrade!,
    ];
    final min = data.scale.minimumValue;
    final max = data.scale.maximumValue;
    final width = (max - min) / binCount;
    final bins = [
      for (var i = 0; i < binCount; i++)
        GradeBin(
          from: min + width * i,
          to: i == binCount - 1 ? max : min + width * (i + 1),
          count: grades.where((g) {
            final from = min + width * i;
            final to = i == binCount - 1 ? max : min + width * (i + 1);
            return i == binCount - 1
                ? g >= from && g <= to
                : g >= from && g < to;
          }).length,
        ),
    ];
    final categories = <CategoryAverage>[];
    final first = data.students.firstOrNull;
    for (final category in first?.categories ?? const <CategoryGrade>[]) {
      final values = [
        for (final s in data.students)
          for (final c in s.categories)
            if (c.categoryId == category.categoryId && c.gradeOnScale != null)
              c.gradeOnScale!,
      ];
      categories.add(
        CategoryAverage(
          name: category.categoryName,
          weight: category.weight,
          average: values.isEmpty
              ? null
              : values.reduce((a, b) => a + b) / values.length,
        ),
      );
    }
    return ClassGradesSummary._(
      students: data.students.length,
      graded: grades.length,
      passing: data.students.where((s) => s.passing == true).length,
      failing: data.students.where((s) => s.passing == false).length,
      average: grades.isEmpty
          ? null
          : grades.reduce((a, b) => a + b) / grades.length,
      highest: grades.isEmpty ? null : grades.reduce((a, b) => a > b ? a : b),
      lowest: grades.isEmpty ? null : grades.reduce((a, b) => a < b ? a : b),
      bins: bins,
      categories: categories,
    );
  }

  final int students;
  final int graded;
  final int passing;
  final int failing;
  final double? average;
  final double? highest;
  final double? lowest;
  final List<GradeBin> bins;
  final List<CategoryAverage> categories;
}
