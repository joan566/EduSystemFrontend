import 'dart:async';

import 'package:flutter/foundation.dart';

import '../events/domain_events.dart';
import 'cached_value.dart';
import 'keyed_cache.dart';

/// Base of every session-level provider (the ones `SessionScope` owns).
///
/// * Its caches are created through [cachedValue]/[keyedCache], so they
///   notify this provider, are marked stale together on
///   [SessionDataReset] (or after a long time in the background) and die
///   with it.
/// * Once the session ends the provider is disposed, but requests it
///   started may still complete: caches drop late responses and
///   [notifyListeners] becomes a no-op, so nothing of a previous session
///   reaches anyone.
/// * It reacts to other providers' changes through [onDomainEvent] and
///   announces its own through [publish] — providers never call each
///   other to keep caches in sync.
abstract class SessionNotifier extends ChangeNotifier {
  SessionNotifier([DomainEvents? events]) : _events = events {
    _subscription = events?.stream.listen(_dispatch);
  }

  /// After this long in the background every cache is re-read on demand
  /// (another device may have changed anything).
  static const staleAfterBackground = Duration(minutes: 15);

  final DomainEvents? _events;
  StreamSubscription<DomainEvent>? _subscription;
  final List<SessionCache> _caches = [];
  bool _disposed = false;

  /// True once the session that owned this provider has ended.
  bool get isDisposed => _disposed;

  @protected
  CachedValue<T> cachedValue<T>({Duration? maxAge}) =>
      _register(CachedValue<T>(maxAge: maxAge, onChanged: notifyListeners));

  @protected
  KeyedCache<K, T> keyedCache<K, T>({int? maxEntries, Duration? maxAge}) =>
      _register(
        KeyedCache<K, T>(
          maxEntries: maxEntries,
          maxAge: maxAge,
          onChanged: notifyListeners,
        ),
      );

  C _register<C extends SessionCache>(C cache) {
    _caches.add(cache);
    return cache;
  }

  /// Announces a successful mutation to the rest of the session.
  @protected
  void publish(DomainEvent event) {
    if (!_disposed) _events?.publish(event);
  }

  /// Reacts to another provider's (or this one's) change. Only mark caches
  /// stale here; never start requests.
  @protected
  void onDomainEvent(DomainEvent event) {}

  void _dispatch(DomainEvent event) {
    if (_disposed) return;
    if (event is SessionDataReset ||
        (event is AppResumed && event.away >= staleAfterBackground)) {
      for (final cache in _caches) {
        cache.invalidateAll();
      }
    }
    onDomainEvent(event);
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    for (final cache in _caches) {
      cache.dispose();
    }
    super.dispose();
  }
}
