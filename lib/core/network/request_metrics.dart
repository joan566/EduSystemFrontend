import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Totals of one `METHOD /route` pair.
class RouteMetrics {
  RouteMetrics(this.method, this.route);

  final String method;

  /// The path with ids replaced by `{id}` (e.g. `/exams/{id}/submissions`).
  final String route;
  int count = 0;
  int failures = 0;
  Duration total = Duration.zero;

  Duration get average => count == 0
      ? Duration.zero
      : Duration(microseconds: total.inMicroseconds ~/ count);

  @override
  String toString() =>
      '$method $route ×$count (avg ${average.inMilliseconds} ms'
      '${failures > 0 ? ', $failures failed' : ''})';
}

/// Counts every request by method and route, to compare how many calls a
/// navigation makes before and after a change. Only enabled in debug
/// builds (see `ApiClient`).
///
/// Records the method, the route template, the status and the duration —
/// never query strings (searches carry names), bodies or headers (the
/// `Authorization` token).
class RequestMetrics {
  RequestMetrics();

  static final RequestMetrics instance = RequestMetrics();

  final Map<String, RouteMetrics> _routes = SplayTreeMap();

  List<RouteMetrics> get routes => List.unmodifiable(_routes.values);

  int get totalRequests => _routes.values.fold(0, (sum, r) => sum + r.count);

  void record(
    String method,
    String path,
    Duration elapsed, {
    bool failed = false,
  }) {
    final route = normalize(path);
    final metrics = _routes.putIfAbsent(
      '$route $method',
      () => RouteMetrics(method, route),
    );
    metrics.count++;
    metrics.total += elapsed;
    if (failed) metrics.failures++;
  }

  void reset() => _routes.clear();

  /// A readable table of everything counted since the last [reset].
  String report() {
    final buffer = StringBuffer('[HTTP] $totalRequests requests\n');
    for (final r in _routes.values) {
      buffer.writeln('  $r');
    }
    return buffer.toString();
  }

  /// `/teaching-periods/12/students/7/grade-report?x=1` →
  /// `/teaching-periods/{id}/students/{id}/grade-report`.
  static String normalize(String path) {
    final withoutQuery = path.split('?').first;
    final uri = Uri.tryParse(withoutQuery);
    final segments = (uri?.path ?? withoutQuery).split('/');
    return segments
        .map((s) => RegExp(r'^\d+$').hasMatch(s) ? '{id}' : s)
        .join('/');
  }
}

/// Feeds [RequestMetrics] and prints one line per request.
class RequestMetricsInterceptor extends Interceptor {
  RequestMetricsInterceptor({RequestMetrics? metrics, this.log = true})
    : _metrics = metrics ?? RequestMetrics.instance;

  final RequestMetrics _metrics;
  final bool log;

  static const _startKey = 'metrics.start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _record(response.requestOptions, response.statusCode, failed: false);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions, err.response?.statusCode, failed: true);
    handler.next(err);
  }

  void _record(RequestOptions options, int? status, {required bool failed}) {
    final start = options.extra[_startKey] as DateTime?;
    final elapsed = start == null
        ? Duration.zero
        : DateTime.now().difference(start);
    _metrics.record(options.method, options.path, elapsed, failed: failed);
    if (log) {
      final route = RequestMetrics.normalize(options.path);
      debugPrint(
        '[HTTP] ${options.method} $route → ${status ?? '-'} '
        '(${elapsed.inMilliseconds} ms) · total ${_metrics.totalRequests}',
      );
    }
  }
}
