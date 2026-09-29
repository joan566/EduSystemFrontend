import '../../../teaching/presentation/shared/class_lookup.dart';
import '../../domain/entities/exam_entity.dart';

/// Exam readiness as the teacher sees it: an exam is "Listo" once every
/// question is configured (answer sheets can be generated), else
/// "Incompleto".
enum ExamStatusFilter { all, incomplete, ready }

enum ExamSort { newest, oldest, name }

String examSortLabel(ExamSort sort) => switch (sort) {
  ExamSort.newest => 'Más recientes primero',
  ExamSort.oldest => 'Más antiguos primero',
  ExamSort.name => 'Nombre (A–Z)',
};

/// Client-side search, status and ordering over the loaded page of exams.
/// Owned by the page entry point so it survives a layout switch.
class ExamListFilters {
  const ExamListFilters({
    this.search = '',
    this.status = ExamStatusFilter.all,
    this.sort = ExamSort.newest,
  });

  final String search;
  final ExamStatusFilter status;
  final ExamSort sort;

  ExamListFilters copyWith({
    String? search,
    ExamStatusFilter? status,
    ExamSort? sort,
  }) => ExamListFilters(
    search: search ?? this.search,
    status: status ?? this.status,
    sort: sort ?? this.sort,
  );

  List<ExamSummaryEntity> apply(List<ExamSummaryEntity> exams) {
    final result = exams
        .where(
          (e) => switch (status) {
            ExamStatusFilter.all => true,
            ExamStatusFilter.incomplete => !e.ready,
            ExamStatusFilter.ready => e.ready,
          },
        )
        .where((e) => matchesSearch(search, [e.name, e.description]))
        .toList();
    switch (sort) {
      case ExamSort.newest:
        result.sort((a, b) => _byDate(a, b, descending: true));
      case ExamSort.oldest:
        result.sort((a, b) => _byDate(a, b, descending: false));
      case ExamSort.name:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return result;
  }

  // Undated exams go last in either direction; ties fall back to creation
  // order (id).
  static int _byDate(
    ExamSummaryEntity a,
    ExamSummaryEntity b, {
    required bool descending,
  }) {
    final da = a.evaluationDate, db = b.evaluationDate;
    if (da == null && db != null) return 1;
    if (db == null && da != null) return -1;
    final byDate = da == null ? 0 : da.compareTo(db!);
    final order = byDate != 0 ? byDate : a.id.compareTo(b.id);
    return descending ? -order : order;
  }
}
