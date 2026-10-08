import '../../../../core/cache/keyed_cache.dart';
import '../../../../core/cache/session_notifier.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/state/list_state.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/exam_entity.dart';

/// Exams, per class (`teachingPeriodId → its exams`, every page) and per
/// exam (`examId → exam with questions`).
///
/// Each class keeps its own list, so the Exámenes screen and a class's
/// screen never overwrite each other's. Create, edit and delete answer with
/// (or imply) the new state, which is written locally: no list is re-read
/// after a mutation.
class ExamsProvider extends SessionNotifier {
  ExamsProvider(this._repository, DomainEvents events) : super(events);

  final ExamRepository _repository;

  late final _exams = keyedCache<int, List<ExamSummaryEntity>>();

  /// Bounded: one per exam opened.
  late final _details = keyedCache<int, ExamEntity>(maxEntries: 30);

  // --- Lists per class -----------------------------------------------------

  /// All the exams of a class, newest first (like the API). Screens filter
  /// and page them in memory.
  ListViewState<ExamSummaryEntity> exams(int teachingPeriodId) =>
      _exams.view(teachingPeriodId);

  Future<void> ensureExams(int teachingPeriodId) => _exams.ensure(
    teachingPeriodId,
    () => _repository.getAll(teachingPeriodId),
  );

  Future<void> refreshExams(int teachingPeriodId) => _exams.refresh(
    teachingPeriodId,
    () => _repository.getAll(teachingPeriodId),
  );

  // --- Detail --------------------------------------------------------------

  DetailViewState<ExamEntity> detail(int examId) => _details.detailView(examId);

  Future<void> ensureDetail(int examId) =>
      _details.ensure(examId, () => _repository.getById(examId));

  Future<void> refreshDetail(int examId) =>
      _details.refresh(examId, () => _repository.getById(examId));

  // --- Mutations -----------------------------------------------------------

  AppException? _lastError;
  AppException? get lastError => _lastError;

  bool _importingDocument = false;
  bool get importingDocument => _importingDocument;

  double? _documentImportProgress;
  double? get documentImportProgress => _documentImportProgress;

  Future<({ExamEntity? exam, AppException? error})> importDocument({
    required int teachingPeriodId,
    required List<int> fileBytes,
    required String fileName,
    String? name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
  }) async {
    if (_importingDocument) {
      return (
        exam: null,
        error: const AppException(
          code: AppErrorCode.invalidRequest,
          message: 'Ya hay una importación de examen en curso.',
        ),
      );
    }
    _importingDocument = true;
    _documentImportProgress = 0;
    notifyListeners();
    try {
      final exam = await _repository.importDocument(
        teachingPeriodId: teachingPeriodId,
        fileBytes: fileBytes,
        fileName: fileName,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        onSendProgress: (sent, total) {
          _documentImportProgress = total > 0 ? sent / total : null;
          notifyListeners();
        },
      );
      _announce(exam.teachingPeriodId);
      _details.set(exam.id, exam);
      _exams.update(exam.teachingPeriodId, (list) => _upsert(list, exam));
      return (exam: exam, error: null);
    } on AppException catch (error) {
      return (exam: null, error: error);
    } finally {
      _importingDocument = false;
      _documentImportProgress = null;
      notifyListeners();
    }
  }

  Future<BinaryDownload> downloadExamTemplate() =>
      _repository.getExamTemplate();

  Future<ExamEntity?> create({
    required int teachingPeriodId,
    required String name,
    String? description,
    DateTime? evaluationDate,
    double? maximumScore,
    required int numberOfQuestions,
  }) async {
    try {
      final exam = await _repository.create(
        teachingPeriodId: teachingPeriodId,
        name: name,
        description: description,
        evaluationDate: evaluationDate,
        maximumScore: maximumScore,
        numberOfQuestions: numberOfQuestions,
      );
      _announce(exam.teachingPeriodId);
      _details.set(exam.id, exam);
      _exams.update(exam.teachingPeriodId, (list) => _upsert(list, exam));
      return exam;
    } on AppException catch (e) {
      _lastError = e;
      return null;
    }
  }

  Future<AppException?> updateMetadata(
    int examId, {
    required String name,
    String? description,
    DateTime? evaluationDate,
  }) => _write(
    () => _repository.update(
      examId,
      name: name,
      description: description,
      evaluationDate: evaluationDate,
    ),
  );

  Future<AppException?> saveQuestions(
    int examId,
    List<ExamQuestion> questions,
  ) => _write(() => _repository.replaceQuestions(examId, questions));

  /// Writes the exam the API answers with into its detail and its class's
  /// list (name, date, readiness).
  Future<AppException?> _write(Future<ExamEntity> Function() request) async {
    try {
      final exam = await request();
      _announce(exam.teachingPeriodId);
      _details.set(exam.id, exam);
      _exams.update(exam.teachingPeriodId, (list) => _upsert(list, exam));
      return null;
    } on AppException catch (e) {
      return e;
    }
  }

  Future<AppException?> delete(int examId) async {
    final teachingPeriodId = _classOf(examId);
    try {
      await _repository.delete(examId);
    } on AppException catch (e) {
      return e;
    }
    if (teachingPeriodId != null) {
      _announce(teachingPeriodId);
      _exams.update(
        teachingPeriodId,
        (list) => list.where((e) => e.id != examId).toList(),
      );
    } else {
      // Unknown class: no list can be patched, so all are re-read later.
      _exams.invalidateAll();
    }
    _details.remove(examId);
    return null;
  }

  Future<BinaryDownload> downloadAnswerSheet(int examId, int studentId) =>
      _repository.getAnswerSheet(examId, studentId);

  /// Exams whose class-wide answer-sheet PDF is being generated (slow), so
  /// every trigger for it shows the work and can't start a second one.
  final Set<int> _generatingSheets = {};

  bool isGeneratingSheets(int examId) => _generatingSheets.contains(examId);

  Future<BinaryDownload> downloadAnswerSheets(int examId) async {
    _generatingSheets.add(examId);
    notifyListeners();
    try {
      return await _repository.getAnswerSheets(examId);
    } finally {
      _generatingSheets.remove(examId);
      notifyListeners();
    }
  }

  // --- Helpers -------------------------------------------------------------

  void _announce(int teachingPeriodId) =>
      publish(ClassDataChanged(teachingPeriodId, const {ClassAspect.exams}));

  int? _classOf(int examId) {
    final fromDetail = _details.dataOf(examId)?.teachingPeriodId;
    if (fromDetail != null) return fromDetail;
    for (final tp in _exams.keys) {
      if (_exams.dataOf(tp)?.any((e) => e.id == examId) ?? false) return tp;
    }
    return null;
  }

  /// Inserts or replaces [exam] (as a list row) keeping the API's order:
  /// newest date first, undated last, then newest first.
  static List<ExamSummaryEntity> _upsert(
    List<ExamSummaryEntity> list,
    ExamEntity exam,
  ) {
    final row = ExamSummaryEntity(
      id: exam.id,
      evaluationId: exam.evaluationId,
      teachingPeriodId: exam.teachingPeriodId,
      name: exam.name,
      description: exam.description,
      evaluationDate: exam.evaluationDate,
      maximumScore: exam.maximumScore,
      numberOfQuestions: exam.numberOfQuestions,
      ready: exam.ready,
    );
    return [
      for (final e in list)
        if (e.id != exam.id) e,
      row,
    ]..sort(_apiOrder);
  }

  static int _apiOrder(ExamSummaryEntity a, ExamSummaryEntity b) {
    final da = a.evaluationDate;
    final db = b.evaluationDate;
    if (da != null && db != null && da != db) return db.compareTo(da);
    if ((da == null) != (db == null)) return da == null ? 1 : -1;
    return b.id.compareTo(a.id);
  }

  @override
  void onDomainEvent(DomainEvent event) {
    // Deleting a class takes its exams with it.
    if (event is CatalogChanged &&
        event.resource == CatalogResource.teachingPeriods &&
        event.change == CatalogChange.deleted) {
      _exams.invalidateAll();
    }
  }
}
