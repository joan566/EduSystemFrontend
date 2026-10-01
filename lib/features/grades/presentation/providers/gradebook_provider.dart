import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/detail_state.dart';
import '../../data/repositories/gradebook_repository.dart';
import '../../domain/entities/gradebook_entities.dart';

/// Students' grade reports per class, grade details per evaluation and a
/// class's evaluations — each cached by its own key, so moving between
/// students (or back to one) never shows another's data and never re-reads
/// what is still valid.
///
/// Mutations write the backend's answer when it carries the new state and
/// otherwise re-read only what they changed; everything derived (reports,
/// period grades, the class summary) goes stale through [ClassDataChanged].
class GradebookProvider extends SessionNotifier {
  GradebookProvider(this._repository, DomainEvents events) : super(events);

  final GradebookRepository _repository;

  /// (teachingPeriodId, studentId) → report. Bounded: one per student
  /// visited.
  late final _reports = keyedCache<(int, int), StudentGradeReport>(
    maxEntries: 60,
  );

  /// (evaluationId, studentId) → detail.
  late final _details = keyedCache<(int, int), GradeDetailEntity>(
    maxEntries: 60,
  );

  late final _evaluations = keyedCache<int, List<EvaluationSummaryEntity>>();

  // --- Reads ---------------------------------------------------------------

  DetailViewState<StudentGradeReport> report(
    int teachingPeriodId,
    int studentId,
  ) => _reports.detailView((teachingPeriodId, studentId));

  Future<void> ensureReport(int teachingPeriodId, int studentId) =>
      _reports.ensure((
        teachingPeriodId,
        studentId,
      ), () => _repository.getReport(teachingPeriodId, studentId));

  Future<void> refreshReport(int teachingPeriodId, int studentId) =>
      _reports.refresh((
        teachingPeriodId,
        studentId,
      ), () => _repository.getReport(teachingPeriodId, studentId));

  DetailViewState<GradeDetailEntity> detail(int evaluationId, int studentId) =>
      _details.detailView((evaluationId, studentId));

  Future<void> ensureDetail(int evaluationId, int studentId) => _details.ensure(
    (evaluationId, studentId),
    () => _repository.getDetail(evaluationId, studentId),
  );

  Future<void> refreshDetail(int evaluationId, int studentId) =>
      _details.refresh((
        evaluationId,
        studentId,
      ), () => _repository.getDetail(evaluationId, studentId));

  /// A class's evaluations (null until read, or if they couldn't be).
  List<EvaluationSummaryEntity>? evaluations(int teachingPeriodId) =>
      _evaluations.dataOf(teachingPeriodId);

  Future<void> ensureEvaluations(int teachingPeriodId) => _evaluations.ensure(
    teachingPeriodId,
    () => _repository.getEvaluations(teachingPeriodId),
  );

  // --- Mutations -----------------------------------------------------------
  // Each one announces what it changed *before* writing its own result, so
  // the fresh value it writes is not marked stale by its own event.

  /// The API answers with the observation, which is patched into the
  /// report.
  Future<AppException?> saveObservation(
    int teachingPeriodId,
    int studentId,
    String text,
  ) => _guard(() async {
    final observation = await _repository.saveObservation(
      teachingPeriodId,
      studentId,
      text,
    );
    _announce(teachingPeriodId, ClassAspect.annotations);
    _reports.update((
      teachingPeriodId,
      studentId,
    ), (report) => report.withObservation(observation));
  });

  Future<AppException?> saveRubric(
    GradeDetailEntity detail,
    List<RubricCriterionInput> criteria,
  ) => _guard(() async {
    await _repository.saveRubric(detail.evaluation.evaluationId, criteria);
    _announce(detail.teachingPeriodId, ClassAspect.grades);
    await _rereadDetail(detail);
  });

  Future<AppException?> deleteRubric(GradeDetailEntity detail) =>
      _guard(() async {
        await _repository.deleteRubric(detail.evaluation.evaluationId);
        _announce(detail.teachingPeriodId, ClassAspect.grades);
        await _rereadDetail(detail);
      });

  /// The API answers with the updated detail.
  Future<AppException?> scoreWithRubric(
    GradeDetailEntity detail, {
    required Map<int, double> scores,
    String? comment,
  }) => _guard(() async {
    final updated = await _repository.scoreWithRubric(
      detail.evaluation.evaluationId,
      detail.student.id,
      scores: scores,
      comment: comment,
    );
    _announce(detail.teachingPeriodId, ClassAspect.grades);
    _details.set(_keyOf(detail), updated);
  });

  Future<AppException?> saveActivityGrade(
    GradeDetailEntity detail, {
    required double grade,
    String? comment,
  }) => _guard(() async {
    await _repository.saveActivityGrade(
      detail.evaluation.activityId!,
      detail.student.id,
      grade: grade,
      comment: comment,
    );
    _announce(detail.teachingPeriodId, ClassAspect.grades);
    await _rereadDetail(detail);
  });

  /// Grade details (evaluation, student) whose attachment is uploading, so
  /// the drop zone / picker show it and can't start a second upload.
  final Set<(int, int)> _uploading = {};

  bool isUploadingAttachment(GradeDetailEntity detail) =>
      _uploading.contains((detail.evaluation.evaluationId, detail.student.id));

  Future<AppException?> uploadAttachment(
    GradeDetailEntity detail, {
    required List<int> bytes,
    required String fileName,
  }) async {
    final key = (detail.evaluation.evaluationId, detail.student.id);
    _uploading.add(key);
    notifyListeners();
    try {
      return await _guard(() async {
        await _repository.uploadAttachment(
          detail.evaluation.evaluationId,
          detail.student.id,
          bytes: bytes,
          fileName: fileName,
        );
        _announce(detail.teachingPeriodId, ClassAspect.annotations);
        await _rereadDetail(detail);
      });
    } finally {
      _uploading.remove(key);
      notifyListeners();
    }
  }

  Future<BinaryDownload> downloadAttachment(GradeDetailEntity detail) =>
      _repository.downloadAttachment(
        detail.evaluation.evaluationId,
        detail.student.id,
      );

  Future<AppException?> deleteAttachment(GradeDetailEntity detail) =>
      _guard(() async {
        await _repository.deleteAttachment(
          detail.evaluation.evaluationId,
          detail.student.id,
        );
        _announce(detail.teachingPeriodId, ClassAspect.annotations);
        await _rereadDetail(detail);
      });

  static (int, int) _keyOf(GradeDetailEntity detail) =>
      (detail.evaluation.evaluationId, detail.student.id);

  /// The endpoint answered without the new state: re-read just this one.
  Future<void> _rereadDetail(GradeDetailEntity detail) =>
      refreshDetail(detail.evaluation.evaluationId, detail.student.id);

  void _announce(int teachingPeriodId, ClassAspect aspect) =>
      publish(ClassDataChanged(teachingPeriodId, {aspect}));

  // --- Invalidation -------------------------------------------------------

  @override
  void onDomainEvent(DomainEvent event) {
    switch (event) {
      case ClassDataChanged(:final teachingPeriodId, :final aspects):
        if (aspects.contains(ClassAspect.schedule) && aspects.length == 1) {
          return; // the timetable doesn't show in grades
        }
        // Reports show every evaluation, grade, weight and note of the
        // class.
        _reports.invalidateWhere((key, _) => key.$1 == teachingPeriodId);
        if (event.affects(const {
          ClassAspect.grades,
          ClassAspect.exams,
          ClassAspect.activities,
          ClassAspect.configuration,
          ClassAspect.annotations,
        })) {
          _details.invalidateWhere(
            (_, detail) => detail?.teachingPeriodId == teachingPeriodId,
          );
        }
        if (event.affects(const {ClassAspect.exams, ClassAspect.activities})) {
          _evaluations.invalidate(teachingPeriodId);
        }
      case ExamResultsChanged(teachingPeriodId: null):
        // The exam's class isn't known here: any class may have changed.
        _reports.invalidateAll();
        _details.invalidateAll();
      case StudentsChanged(:final studentId):
        _reports.invalidateWhere(
          (key, _) => studentId == null || key.$2 == studentId,
        );
        _details.invalidateWhere(
          (key, _) => studentId == null || key.$2 == studentId,
        );
      default:
        break;
    }
  }

  Future<AppException?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e;
    }
  }
}
