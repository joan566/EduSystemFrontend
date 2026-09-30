import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../state/detail_state.dart';
import '../state/list_state.dart';

/// Anything a provider can mark stale or throw away in one go.
abstract interface class SessionCache {
  /// Marks every cached value stale (they are re-read when next needed).
  void invalidateAll();

  /// Stops notifying and drops any late response.
  void dispose();
}

/// One cached backend resource: its data, the last error, when it was
/// fetched, whether it is stale, and the request in flight.
///
/// * [ensure] reads it only when needed: nothing cached yet, the last
///   attempt failed, it was [invalidate]d, or it is older than [maxAge].
/// * [refresh] always reads it (pull-to-refresh, "retry").
/// * Concurrent callers share one request: two widgets that [ensure] the
///   same value at once produce a single GET.
/// * While a refresh runs the previous data stays visible.
/// * [set]/[update] write the backend's answer to a mutation locally.
/// * A response that started before a local write or an invalidation is
///   discarded (it may predate that change) and the value stays stale, so
///   an older response can never overwrite a newer state.
/// * After [dispose] (the session ended) nothing is written or notified.
class CachedValue<T> implements SessionCache {
  CachedValue({
    this.maxAge,
    VoidCallback? onChanged,
    DateTime Function()? clock,
  }) : _onChanged = onChanged,
       _clock = clock ?? DateTime.now;

  /// How long fetched data counts as fresh. Null: until invalidated (most
  /// resources — only time-sensitive ones have a TTL).
  final Duration? maxAge;

  final VoidCallback? _onChanged;
  final DateTime Function() _clock;

  T? _data;
  bool _hasData = false;
  AppException? _error;
  DateTime? _fetchedAt;
  bool _stale = false;
  bool _disposed = false;

  /// Bumped by every local write, invalidation and clear. A response is
  /// only applied if nothing happened since its request started.
  int _version = 0;
  Object? _inflightToken;
  int _inflightVersion = 0;
  Future<void>? _inflight;

  bool get hasData => _hasData;
  T? get data => _data;

  /// The last attempt's error; kept alongside the previous data (if any).
  AppException? get error => _error;
  DateTime? get fetchedAt => _fetchedAt;
  bool get isLoading => _inflight != null;

  bool get isStale =>
      _stale ||
      (maxAge != null &&
          _fetchedAt != null &&
          _clock().difference(_fetchedAt!) >= maxAge!);

  /// Whether [ensure] would hit the backend.
  bool get needsFetch => !_disposed && (!_hasData || _error != null || isStale);

  /// Reads the value if it isn't usable yet. Never throws: the outcome is
  /// in [data]/[error].
  Future<void> ensure(Future<T> Function() fetch) {
    final inflight = _joinable(() => ensure(fetch));
    if (inflight != null) return inflight;
    if (!needsFetch) return Future.value();
    return _start(fetch);
  }

  /// Reads the value now, keeping the current data visible meanwhile. Joins
  /// the request already in flight, if any.
  Future<void> refresh(Future<T> Function() fetch) {
    if (_disposed) return Future.value();
    return _joinable(() => refresh(fetch)) ?? _start(fetch);
  }

  /// The request in flight to wait for, if any. One that started before
  /// the latest write/invalidation will be discarded, so [retry] runs after
  /// it (and joins or starts the next one).
  Future<void>? _joinable(Future<void> Function() retry) {
    final inflight = _inflight;
    if (inflight == null) return null;
    return _inflightVersion == _version
        ? inflight
        : inflight.then((_) => retry());
  }

  Future<void> _start(Future<T> Function() fetch) {
    final token = Object();
    final future = _run(fetch, token, _version);
    // `_run` doesn't settle before its first await, so recording it here is
    // safe; it only clears `_inflight` if the token still matches.
    _inflightToken = token;
    _inflightVersion = _version;
    _inflight = future;
    _notify();
    return future;
  }

  Future<void> _run(
    Future<T> Function() fetch,
    Object token,
    int version,
  ) async {
    await null; // Let `_start` record the request before it can settle.
    try {
      final value = await fetch();
      if (_disposed || !identical(token, _inflightToken)) return;
      if (version != _version) {
        // Something was written or invalidated meanwhile: this answer may
        // be older than that, so it is dropped and re-read when needed.
        _stale = true;
      } else {
        _data = value;
        _hasData = true;
        _error = null;
        _stale = false;
        _fetchedAt = _clock();
      }
    } catch (e) {
      if (_disposed || !identical(token, _inflightToken)) return;
      if (version == _version) {
        _error = e is AppException
            ? e
            : const AppException(
                code: AppErrorCode.unknown,
                message: 'An unexpected error occurred.',
              );
      }
    } finally {
      if (!_disposed && identical(token, _inflightToken)) {
        _inflightToken = null;
        _inflight = null;
        _notify();
      }
    }
  }

  /// Replaces the value with the backend's answer to a mutation.
  void set(T value) {
    if (_disposed) return;
    _version++;
    _data = value;
    _hasData = true;
    _error = null;
    _stale = false;
    _fetchedAt = _clock();
    _notify();
  }

  /// Patches the cached value. Does nothing when nothing is cached: the
  /// next [ensure] reads the complete value anyway.
  void update(T Function(T current) change) {
    if (_disposed || !_hasData) return;
    set(change(_data as T));
  }

  /// Marks the value stale without reading it: it is re-read the next time
  /// someone [ensure]s it. A request in flight is not trusted either.
  void invalidate() {
    if (_disposed || (!_hasData && _inflight == null)) return;
    _version++;
    _stale = true;
  }

  @override
  void invalidateAll() => invalidate();

  /// Forgets everything (e.g. the resource was deleted).
  void clear() {
    if (_disposed) return;
    _version++;
    _data = null;
    _hasData = false;
    _error = null;
    _stale = false;
    _fetchedAt = null;
    _inflightToken = null;
    _inflight = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _inflightToken = null;
    _inflight = null;
  }

  void _notify() {
    if (!_disposed) _onChanged?.call();
  }

  /// The single-entity screen state: data wins over a refresh in flight or
  /// a failed refresh, so revisiting never flashes a spinner.
  DetailViewState<T> get detailView {
    if (_hasData) return DetailViewState<T>.success(_data as T);
    if (_inflight != null) return DetailViewState<T>.loading();
    if (_error != null) return DetailViewState<T>.error(_error!);
    return DetailViewState<T>();
  }

  /// A list screen state built by [ready] from the cached data, with the
  /// same loading/error rules as [detailView].
  ListViewState<E> listView<E>(ListViewState<E> Function(T data) ready) {
    if (_hasData) return ready(_data as T);
    if (_inflight != null) return ListViewState<E>.loading();
    if (_error != null) return ListViewState<E>.error(_error!);
    return ListViewState<E>();
  }
}

extension CachedListView<E> on CachedValue<List<E>> {
  /// The whole cached list as a single-page screen state.
  ListViewState<E> get view => listView((items) => ListViewState.list(items));
}

extension CachedPageView<E> on CachedValue<ApiPage<E>> {
  /// A cached server page as a screen state.
  ListViewState<E> get view => listView(
    (page) => ListViewState.fromPage(
      content: page.content,
      page: page.page,
      totalPages: page.totalPages,
      totalElements: page.totalElements,
    ),
  );
}

/// One page of a list held in memory (a catalog): pagination stays in the
/// UI, but paging and filtering never hit the backend.
ListViewState<E> localPage<E>(List<E> items, {int page = 0, int size = 20}) {
  final totalPages = items.isEmpty ? 0 : (items.length + size - 1) ~/ size;
  final current = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
  final start = current * size;
  return ListViewState.fromPage(
    content: items.sublist(start, (start + size).clamp(0, items.length)),
    page: current,
    totalPages: totalPages,
    totalElements: items.length,
  );
}
