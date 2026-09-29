import '../../../teaching/domain/entities/teaching_period_entity.dart';

/// Where a subject is taught: the teacher's classes of it, by subject id.
Map<int, List<TeachingPeriodEntity>> classesBySubject(
  List<TeachingPeriodEntity> classes,
) {
  final result = <int, List<TeachingPeriodEntity>>{};
  for (final c in classes) {
    (result[c.subjectId] ??= []).add(c);
  }
  return result;
}

/// "5° A, 6° B" — the distinct courses among [classes].
String coursesLabel(List<TeachingPeriodEntity> classes) =>
    {for (final c in classes) c.courseLabel}.join(', ');

String classesCountLabel(int count) => switch (count) {
  0 => 'Sin clases asignadas',
  1 => '1 clase',
  _ => '$count clases',
};
