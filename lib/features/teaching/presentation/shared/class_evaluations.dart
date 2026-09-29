import '../../../../core/router/route_paths.dart';
import '../../../activities/domain/entities/activity_entity.dart';
import '../../../exams/domain/entities/exam_entity.dart';

enum ClassEvaluationKind { exam, activity }

/// An exam or an activity of a class, as one row of its evaluations.
class ClassEvaluationItem {
  const ClassEvaluationItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.date,
    required this.detail,
  });

  factory ClassEvaluationItem.exam(ExamSummaryEntity e) => ClassEvaluationItem(
    kind: ClassEvaluationKind.exam,
    id: e.id,
    name: e.name,
    date: e.evaluationDate,
    detail: '${e.numberOfQuestions} preguntas',
  );

  factory ClassEvaluationItem.activity(ActivityEntity a) => ClassEvaluationItem(
    kind: ClassEvaluationKind.activity,
    id: a.id,
    name: a.name,
    date: a.evaluationDate,
    detail:
        '${a.activityType ?? 'Actividad'} · máx. '
        '${a.maximumScore.toStringAsFixed(1)}',
  );

  final ClassEvaluationKind kind;
  final int id;
  final String name;
  final DateTime? date;
  final String detail;

  String get kindLabel =>
      kind == ClassEvaluationKind.exam ? 'Examen' : 'Actividad';

  String get route => kind == ClassEvaluationKind.exam
      ? RoutePaths.examDetail(id)
      : RoutePaths.activityDetail(id);
}

/// Exams and activities merged, newest first (dated ones before undated).
List<ClassEvaluationItem> mergeClassEvaluations(
  List<ExamSummaryEntity> exams,
  List<ActivityEntity> activities,
) {
  final items = [
    ...exams.map(ClassEvaluationItem.exam),
    ...activities.map(ClassEvaluationItem.activity),
  ];
  items.sort((a, b) {
    final da = a.date;
    final db = b.date;
    if (da == null && db == null) return b.id.compareTo(a.id);
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });
  return items;
}
