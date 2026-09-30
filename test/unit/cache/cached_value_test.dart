import 'dart:async';

import 'package:edusistem_front/core/cache/cached_value.dart';
import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/state/detail_state.dart';
import 'package:edusistem_front/core/state/list_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fetch whose calls are counted and completed by hand.
class _Fetch<T> {
  final List<Completer<T>> calls = [];

  Future<T> call() {
    final completer = Completer<T>();
    calls.add(completer);
    return completer.future;
  }
}

const _boom = AppException(code: AppErrorCode.network, message: 'offline');

void main() {
  late int notifications;
  late CachedValue<int> value;
  late _Fetch<int> fetch;

  setUp(() {
    notifications = 0;
    fetch = _Fetch<int>();
    value = CachedValue<int>(onChanged: () => notifications++);
  });

  test('ensure fetches once, then serves memory', () async {
    final first = value.ensure(fetch.call);
    await pumpEventQueue();
    expect(fetch.calls, hasLength(1));
    expect(value.isLoading, isTrue);
    fetch.calls.single.complete(7);
    await first;

    expect(value.data, 7);
    expect(value.isLoading, isFalse);
    expect(value.detailView.status, DetailStatus.success);

    await value.ensure(fetch.call);
    expect(fetch.calls, hasLength(1), reason: 'fresh data is not re-read');
  });

  test('two simultaneous ensure calls share one request', () async {
    final a = value.ensure(fetch.call);
    final b = value.ensure(fetch.call);
    await pumpEventQueue();
    expect(fetch.calls, hasLength(1));
    fetch.calls.single.complete(3);
    await Future.wait([a, b]);
    expect(value.data, 3);
  });

  test(
    'invalidate marks stale without fetching; next ensure re-reads',
    () async {
      value.set(1);
      value.invalidate();
      await pumpEventQueue();
      expect(fetch.calls, isEmpty, reason: 'invalidate never fetches');
      expect(value.isStale, isTrue);
      expect(value.data, 1, reason: 'stale data stays visible');

      final future = value.ensure(fetch.call);
      await pumpEventQueue();
      expect(fetch.calls, hasLength(1));
      fetch.calls.single.complete(2);
      await future;
      expect(value.data, 2);
      expect(value.isStale, isFalse);
    },
  );

  test('refresh always fetches and keeps data visible meanwhile', () async {
    value.set(1);
    final future = value.refresh(fetch.call);
    await pumpEventQueue();
    expect(fetch.calls, hasLength(1));
    expect(value.detailView.data, 1, reason: 'no destructive spinner');
    expect(value.detailView.status, DetailStatus.success);
    fetch.calls.single.complete(5);
    await future;
    expect(value.data, 5);
  });

  test('set and update write locally and notify', () {
    value.update((v) => v + 1);
    expect(value.hasData, isFalse, reason: 'nothing to patch yet');

    value.set(10);
    value.update((v) => v + 1);
    expect(value.data, 11);
    expect(notifications, 2);
    expect(value.needsFetch, isFalse);
  });

  test('an error is kept, old data survives, and ensure retries', () async {
    final first = value.ensure(fetch.call);
    await pumpEventQueue();
    fetch.calls.single.completeError(_boom);
    await first;
    expect(value.detailView.status, DetailStatus.error);
    expect(value.error, _boom);
    expect(value.needsFetch, isTrue);

    final retry = value.ensure(fetch.call);
    await pumpEventQueue();
    expect(fetch.calls, hasLength(2));
    fetch.calls.last.complete(4);
    await retry;
    expect(value.data, 4);
    expect(value.error, isNull);

    // A failed refresh keeps the previous data on screen.
    final again = value.refresh(fetch.call);
    await pumpEventQueue();
    fetch.calls.last.completeError(_boom);
    await again;
    expect(value.data, 4);
    expect(value.detailView.status, DetailStatus.success);
    expect(value.error, _boom);
  });

  test('non-AppException failures become AppException', () async {
    final future = value.ensure(fetch.call);
    await pumpEventQueue();
    fetch.calls.single.completeError(StateError('bad json'));
    await future;
    expect(value.error?.code, AppErrorCode.unknown);
  });

  test('a response older than a local write is discarded', () async {
    final future = value.ensure(fetch.call);
    await pumpEventQueue();
    value.set(99); // e.g. the answer to a POST arrives first
    fetch.calls.single.complete(1);
    await future;
    expect(value.data, 99, reason: 'the older GET must not win');
    expect(value.isStale, isTrue, reason: 're-read when next needed');
  });

  test('joining an invalidated request re-reads after it', () async {
    final first = value.ensure(fetch.call);
    await pumpEventQueue();
    value.invalidate();
    final joined = value.ensure(fetch.call);
    fetch.calls.first.complete(1);
    await pumpEventQueue();
    expect(fetch.calls, hasLength(2), reason: 'the outdated answer is dropped');
    fetch.calls.last.complete(2);
    await Future.wait([first, joined]);
    expect(value.data, 2);
  });

  test('maxAge makes data stale after it expires', () async {
    var now = DateTime(2026, 1, 1, 8);
    final timed = CachedValue<int>(
      maxAge: const Duration(minutes: 5),
      clock: () => now,
    );
    timed.set(1);
    expect(timed.needsFetch, isFalse);
    now = now.add(const Duration(minutes: 5));
    expect(timed.isStale, isTrue);
    expect(timed.needsFetch, isTrue);
  });

  test('after dispose a late response writes nothing', () async {
    final future = value.ensure(fetch.call);
    await pumpEventQueue();
    final before = notifications;
    value.dispose();
    fetch.calls.single.complete(42);
    await future;
    expect(value.hasData, isFalse);
    expect(notifications, before);
    await value.ensure(fetch.call);
    expect(fetch.calls, hasLength(1), reason: 'a disposed cache never fetches');
  });

  test('clear forgets data and ignores the request in flight', () async {
    final future = value.ensure(fetch.call);
    await pumpEventQueue();
    value.clear();
    fetch.calls.single.complete(8);
    await future;
    expect(value.hasData, isFalse);
  });

  test('list and page views map cache state to screen state', () {
    final list = CachedValue<List<int>>();
    expect(list.view.status, ViewStatus.initial);
    list.set([]);
    expect(list.view.status, ViewStatus.empty);
    list.set([1, 2]);
    expect(list.view.items, [1, 2]);

    final page = localPage(List.generate(45, (i) => i), page: 2);
    expect(page.items, [40, 41, 42, 43, 44]);
    expect(page.totalPages, 3);
    expect(page.totalElements, 45);
    expect(localPage(List.generate(5, (i) => i), page: 9).page, 0);
  });
}
