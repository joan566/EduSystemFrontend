import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../state/detail_state.dart';
import '../state/list_state.dart';
import 'cached_value.dart';

/// A [CachedValue] per key: `teachingPeriodId → exams`,
/// `(teachingPeriodId, studentId) → report`, `(examId, submissionId) →
/// submission`... Each key is independent (its own request, staleness and
/// error), so two screens showing different keys never overwrite each
/// other.
///
/// With [maxEntries] it keeps only the most recently used keys (for
/// resources that can grow without bound, like per-student details);
/// catalogs and per-class data of one teacher are small and don't need it.
class KeyedCache<K, T> implements SessionCache {
  KeyedCache({
    this.maxEntries,
    this.maxAge,
    VoidCallback? onChanged,
    DateTime Function()? clock,
  }) : _onChanged = onChanged,
       _clock = clock;

  final int? maxEntries;
  final Duration? maxAge;
  final VoidCallback? _onChanged;
  final DateTime Function()? _clock;

  // Insertion order doubles as recency order (entries are re-inserted on
  // use), so the first key is the least recently used.
  final LinkedHashMap<K, CachedValue<T>> _entries =
      LinkedHashMap<K, CachedValue<T>>();
  bool _disposed = false;

  /// The entry for [key] if one exists; never creates one (safe to call
  /// from `build`).
  CachedValue<T>? peek(K key) => _entries[key];

  T? dataOf(K key) => _entries[key]?.data;

  Iterable<K> get keys => _entries.keys;

  /// The entry for [key], created (empty) on first use.
  CachedValue<T> entry(K key) {
    final existing = _entries.remove(key);
    final value =
        existing ??
        CachedValue<T>(maxAge: maxAge, onChanged: _onChanged, clock: _clock);
    _entries[key] = value;
    _evict();
    return value;
  }

  Future<void> ensure(K key, Future<T> Function() fetch) =>
      _disposed ? Future.value() : entry(key).ensure(fetch);

  Future<void> refresh(K key, Future<T> Function() fetch) =>
      _disposed ? Future.value() : entry(key).refresh(fetch);

  void set(K key, T value) {
    if (!_disposed) entry(key).set(value);
  }

  /// Patches [key]'s value if it is cached.
  void update(K key, T Function(T current) change) =>
      _entries[key]?.update(change);

  void invalidate(K key) => _entries[key]?.invalidate();

  /// Marks stale every entry whose key (or cached value) matches.
  void invalidateWhere(bool Function(K key, T? value) test) {
    for (final e in _entries.entries) {
      if (test(e.key, e.value.data)) e.value.invalidate();
    }
  }

  @override
  void invalidateAll() {
    for (final value in _entries.values) {
      value.invalidate();
    }
  }

  /// Forgets [key] entirely (e.g. the resource was deleted).
  void remove(K key) {
    final value = _entries.remove(key);
    if (value == null) return;
    value.dispose();
    _onChanged?.call();
  }

  void removeWhere(bool Function(K key, T? value) test) {
    final gone = [
      for (final e in _entries.entries)
        if (test(e.key, e.value.data)) e.key,
    ];
    for (final key in gone) {
      _entries.remove(key)?.dispose();
    }
    if (gone.isNotEmpty) _onChanged?.call();
  }

  void _evict() {
    final max = maxEntries;
    if (max == null) return;
    // Oldest first; an entry with a request in flight is kept so its
    // callers still get their answer.
    final excess = _entries.length - max;
    if (excess <= 0) return;
    final victims = _entries.entries
        .where((e) => !e.value.isLoading)
        .take(excess)
        .map((e) => e.key)
        .toList();
    for (final key in victims) {
      _entries.remove(key)?.dispose();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final value in _entries.values) {
      value.dispose();
    }
  }

  /// [key]'s single-entity screen state (initial when never requested).
  DetailViewState<T> detailView(K key) =>
      _entries[key]?.detailView ?? DetailViewState<T>();

  /// [key]'s list screen state built by [ready] from its data.
  ListViewState<E> listView<E>(
    K key,
    ListViewState<E> Function(T data) ready,
  ) => _entries[key]?.listView(ready) ?? ListViewState<E>();
}

extension KeyedListView<K, E> on KeyedCache<K, List<E>> {
  ListViewState<E> view(K key) =>
      listView(key, (items) => ListViewState.list(items));
}

extension KeyedPageView<K, E> on KeyedCache<K, ApiPage<E>> {
  ListViewState<E> view(K key) => listView(
    key,
    (page) => ListViewState.fromPage(
      content: page.content,
      page: page.page,
      totalPages: page.totalPages,
      totalElements: page.totalElements,
    ),
  );
}
