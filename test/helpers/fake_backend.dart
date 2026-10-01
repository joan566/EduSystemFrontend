import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/network/request_metrics.dart';
import 'package:edusistem_front/core/storage/token_storage.dart';

typedef Handler = FutureOr<Object?> Function(RequestOptions request);

/// An in-memory backend behind the real [ApiClient] (Dio adapter), so tests
/// exercise provider → repository → datasource → ApiClient and count the
/// requests actually sent.
///
/// Routes are `METHOD /path/{id}` templates. A route can be [hold]-ed so
/// its responses wait until released (to test concurrency and late
/// responses).
class FakeBackend implements HttpClientAdapter {
  final Map<String, Handler> _routes = {};
  final Map<String, List<Completer<void>>> _gates = {};
  final RequestMetrics metrics = RequestMetrics();

  /// Every request sent, as `METHOD /path` (ids kept).
  final List<String> log = [];

  void on(String method, String route, Handler handler) =>
      _routes['$method $route'] = handler;

  /// Requests sent to `METHOD route` (ids normalized to `{id}`).
  int count(String method, String route) => metrics.routes
      .where((r) => r.method == method && r.route == route)
      .fold(0, (sum, r) => sum + r.count);

  int get total => metrics.totalRequests;

  /// Makes the next responses of `METHOD route` wait until the returned
  /// completer is completed.
  Completer<void> hold(String method, String route) {
    final gate = Completer<void>();
    (_gates['$method $route'] ??= []).add(gate);
    return gate;
  }

  ApiClient client() => ApiClient(
    onSessionExpired: () async {},
    httpClientAdapter: this,
    tokenStorage: MemoryTokenStorage(),
    metrics: metrics,
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = RequestMetrics.normalize(options.path);
    final key = '${options.method} $route';
    log.add('${options.method} ${options.path}');
    final gates = _gates[key];
    if (gates != null && gates.isNotEmpty) await gates.removeAt(0).future;
    final handler = _routes[key];
    if (handler == null) {
      return ResponseBody.fromString(
        jsonEncode({'code': 'NOT_FOUND', 'message': 'No route $key'}),
        404,
        headers: _json,
      );
    }
    try {
      final body = await handler(options);
      return ResponseBody.fromString(
        body == null ? '' : jsonEncode(body),
        body == null ? 204 : 200,
        headers: _json,
      );
    } on FakeHttpError catch (e) {
      return ResponseBody.fromString(
        jsonEncode({'code': e.code, 'message': e.code}),
        e.status,
        headers: _json,
      );
    }
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

/// Thrown by a handler to answer with an HTTP error.
class FakeHttpError implements Exception {
  const FakeHttpError(this.status, [this.code = 'ERROR']);
  final int status;
  final String code;
}

/// The backend's `[PAGE]` envelope for [all], sliced by the request's
/// `page`/`size` like the API does.
Map<String, Object?> pageOf(List<Map<String, Object?>> all, RequestOptions r) {
  final page = int.parse('${r.queryParameters['page'] ?? 0}');
  final size = int.parse('${r.queryParameters['size'] ?? 20}');
  final start = (page * size).clamp(0, all.length);
  final end = (start + size).clamp(0, all.length);
  return {
    'content': all.sublist(start, end),
    'page': page,
    'size': size,
    'totalElements': all.length,
    'totalPages': all.isEmpty ? 0 : (all.length + size - 1) ~/ size,
  };
}

class MemoryTokenStorage extends TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> save(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

/// Collects the domain events published on [events].
List<DomainEvent> recordEvents(DomainEvents events) {
  final seen = <DomainEvent>[];
  events.stream.listen(seen.add);
  return seen;
}

// --- JSON fixtures -----------------------------------------------------------

Map<String, Object?> subjectJson(int id, String name) => {
  'id': id,
  'name': name,
  'description': null,
};

Map<String, Object?> courseJson(int id, {int gradeId = 1, String name = 'A'}) =>
    {
      'id': id,
      'gradeId': gradeId,
      'gradeName': 'Grado $gradeId',
      'name': name,
      'academicYear': 2026,
    };

Map<String, Object?> assignmentJson(int id, {bool active = true}) => {
  'id': id,
  'groupId': 10 + id,
  'groupName': 'G$id',
  'gradeName': '5°',
  'academicYear': 2026,
  'subjectId': 100 + id,
  'subjectName': 'Materia $id',
  'active': active,
};

Map<String, Object?> periodJson(
  int id, {
  int groupId = 1,
  String subject = 'Matemáticas',
  int studentCount = 30,
}) => {
  'id': id,
  'teachingAssignmentId': id,
  'groupId': groupId,
  'groupName': 'A',
  'gradeName': '5°',
  'academicYear': 2026,
  'subjectId': id,
  'subjectName': '$subject $id',
  'academicPeriodId': 1,
  'academicPeriodName': '2026-1',
  'startDate': '2026-02-01',
  'endDate': '2026-06-30',
  'studentCount': studentCount,
};

Map<String, Object?> summaryJson(int teachingPeriodId) => {
  'teachingPeriodId': teachingPeriodId,
  'studentCount': 30,
  'activityCount': 2,
  'examCount': 1,
  'grading': {
    'expectedGrades': 90,
    'registeredGrades': 45,
    'progressPercent': 50,
  },
};

Map<String, Object?> examJson(
  int id, {
  int teachingPeriodId = 1,
  String name = 'Parcial',
  String? date = '2026-03-01T08:00:00',
}) => {
  'id': id,
  'evaluationId': 500 + id,
  'teachingPeriodId': teachingPeriodId,
  'name': name,
  'description': null,
  'evaluationDate': date,
  'maximumScore': 5,
  'numberOfQuestions': 10,
  'ready': false,
  'optionCount': 4,
  'questions': const [],
};

Map<String, Object?> activityJson(int id, {int teachingPeriodId = 1}) => {
  'id': id,
  'evaluationId': 700 + id,
  'teachingPeriodId': teachingPeriodId,
  'name': 'Taller $id',
  'description': null,
  'evaluationDate': '2026-03-0${id % 9 + 1}T08:00:00',
  'maximumScore': 5,
  'activityType': 'TALLER',
};

Map<String, Object?> activityGradeJson(int studentId, double? grade) => {
  'studentId': studentId,
  'studentCode': 'E$studentId',
  'studentName': 'Estudiante $studentId',
  'grade': grade,
  'comment': null,
  'gradedAt': null,
};

Map<String, Object?> scaleJson() => {
  'id': 1,
  'name': '1-5',
  'minimumValue': 1,
  'maximumValue': 5,
};

Map<String, Object?> periodGradesJson(
  int teachingPeriodId,
  List<int> studentIds,
) => {
  'teachingPeriodId': teachingPeriodId,
  'scale': scaleJson(),
  'passingGrade': 3,
  'students': [
    for (final id in studentIds)
      {
        'studentId': id,
        'studentCode': 'E$id',
        'studentName': 'Estudiante $id',
        'periodGrade': 3.5 + teachingPeriodId / 10,
        'passing': true,
        'categories': const [],
      },
  ],
};

Map<String, Object?> sessionJson(int id, String date, {int tp = 1}) => {
  'id': id,
  'evaluationId': 900 + id,
  'teachingPeriodId': tp,
  'name': null,
  'sessionDate': date,
  'maximumScore': 5,
};

Map<String, Object?> recordJson(int studentId, String? status) => {
  'studentId': studentId,
  'studentCode': 'E$studentId',
  'studentName': 'Estudiante $studentId',
  'status': status,
  'observation': null,
};

Map<String, Object?> _gradebookStudent(int id) => {
  'id': id,
  'studentCode': 'E$id',
  'firstName': 'Ana $id',
  'lastName': 'Pérez',
};

Map<String, Object?> _entryJson({
  int evaluationId = 701,
  int? activityId = 1,
}) => {
  'evaluationId': evaluationId,
  'name': 'Taller',
  'description': null,
  'type': 'ACTIVITY',
  'activityType': 'TALLER',
  'categoryId': 1,
  'categoryName': 'Talleres',
  'evaluationDate': null,
  'maximumScore': 5,
  'earned': 4,
  'excluded': false,
  'weight': null,
  'contribution': null,
  'comment': null,
  'gradedAt': null,
  'activityId': activityId,
  'examId': null,
  'submissionId': null,
  'hasRubric': false,
  'hasAttachment': false,
};

Map<String, Object?> reportJson(
  int teachingPeriodId,
  int studentId, {
  String? observation,
}) => {
  'teachingPeriodId': teachingPeriodId,
  'student': _gradebookStudent(studentId),
  'scale': scaleJson(),
  'passingGrade': 3,
  'totalWeight': 100,
  'configurationComplete': true,
  'periodGrade': 4,
  'score': 80,
  'passing': true,
  'categories': const [],
  'evaluations': [_entryJson()],
  'observation': observation == null
      ? null
      : {'text': observation, 'updatedAt': null},
};

Map<String, Object?> gradeDetailJson(
  int teachingPeriodId,
  int evaluationId,
  int studentId,
) => {
  'teachingPeriodId': teachingPeriodId,
  'student': _gradebookStudent(studentId),
  'scale': scaleJson(),
  'evaluation': _entryJson(evaluationId: evaluationId),
  'rubric': const [],
  'attachment': null,
};

Map<String, Object?> studentJson(int id, {String lastName = 'Pérez'}) => {
  'id': id,
  'studentCode': 'E$id',
  'identificationNumber': '$id',
  'firstName': 'Ana $id',
  'lastName': lastName,
  'active': true,
};

/// An import as `POST /imports/...` (202) and `GET /imports/{id}` return
/// it; counts stay null until [total] is given.
Map<String, Object?> importJson(
  int id,
  String status, {
  String? type = 'STUDENTS',
  int? total,
  int? successful,
  String? errorCode,
  String? errorMessage,
  List<Map<String, Object?>> errors = const [],
  bool errorsTruncated = false,
}) => {
  'id': id,
  'type': type,
  'fileName': 'archivo.xlsx',
  'status': status,
  'totalRows': total,
  'successfulRows': successful,
  'failedRows': total == null ? null : total - (successful ?? 0),
  'hasErrorReport': total != null && total > (successful ?? 0),
  'errorCode': errorCode,
  'errorMessage': errorMessage,
  'createdAt': '2026-10-01T14:03:11',
  'startedAt': status == 'QUEUED' ? null : '2026-10-01T14:03:11',
  'completedAt': null,
  'errors': errors,
  'errorsTruncated': errorsTruncated,
};
