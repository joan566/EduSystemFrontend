import 'dart:async';

import 'package:edusistem_front/core/cache/keyed_cache.dart';
import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/state/detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keys are independent', () async {
    final cache = KeyedCache<int, String>();
    await cache.ensure(1, () async => 'one');
    await cache.ensure(2, () async => 'two');
    expect(cache.dataOf(1), 'one');
    expect(cache.dataOf(2), 'two');

    cache.invalidate(1);
    expect(cache.peek(1)!.isStale, isTrue);
    expect(cache.peek(2)!.isStale, isFalse);
    expect(cache.detailView(3).status, DetailStatus.initial);
    expect(cache.peek(3), isNull, reason: 'reading never creates entries');
  });

  test('record keys compare by value', () async {
    final cache = KeyedCache<(int, int), int>();
    var calls = 0;
    await cache.ensure((1, 2), () async => ++calls);
    await cache.ensure((1, 2), () async => ++calls);
    expect(calls, 1);
  });

  test('concurrent ensures of one key share a request', () async {
    final cache = KeyedCache<int, int>();
    final completer = Completer<int>();
    var calls = 0;
    Future<int> fetch() {
      calls++;
      return completer.future;
    }

    final a = cache.ensure(5, fetch);
    final b = cache.ensure(5, fetch);
    await pumpEventQueue();
    expect(calls, 1);
    completer.complete(9);
    await Future.wait([a, b]);
    expect(cache.dataOf(5), 9);
  });

  test('invalidateWhere and invalidateAll', () async {
    final cache = KeyedCache<(int, int), int>();
    cache.set((1, 1), 11);
    cache.set((1, 2), 12);
    cache.set((2, 1), 21);
    cache.invalidateWhere((key, _) => key.$1 == 1);
    expect(cache.peek((1, 1))!.isStale, isTrue);
    expect(cache.peek((1, 2))!.isStale, isTrue);
    expect(cache.peek((2, 1))!.isStale, isFalse);

    cache.invalidateAll();
    expect(cache.peek((2, 1))!.isStale, isTrue);
  });

  test('update patches cached keys only; remove forgets', () {
    final cache = KeyedCache<int, List<int>>();
    cache.set(1, [1]);
    cache.update(1, (l) => [...l, 2]);
    cache.update(2, (l) => [...l, 2]);
    expect(cache.dataOf(1), [1, 2]);
    expect(cache.peek(2), isNull);

    cache.remove(1);
    expect(cache.peek(1), isNull);
  });

  test('LRU keeps only the most recently used keys', () async {
    final cache = KeyedCache<int, int>(maxEntries: 2);
    cache.set(1, 1);
    cache.set(2, 2);
    cache.entry(1); // use 1 again: 2 becomes the oldest
    cache.set(3, 3);
    expect(cache.keys, unorderedEquals([1, 3]));
  });

  test('LRU never evicts an entry with a request in flight', () async {
    final cache = KeyedCache<int, int>(maxEntries: 1);
    final pending = Completer<int>();
    final future = cache.ensure(1, () => pending.future);
    await pumpEventQueue();
    cache.set(2, 2);
    expect(cache.keys, contains(1));
    pending.complete(1);
    await future;
    expect(cache.dataOf(1), 1);
  });

  test('dispose drops late responses of every key', () async {
    final cache = KeyedCache<int, int>();
    final pending = Completer<int>();
    final future = cache.ensure(1, () => pending.future);
    await pumpEventQueue();
    cache.dispose();
    pending.complete(1);
    await future;
    expect(cache.dataOf(1), isNull);
  });

  group('DomainEvents', () {
    test('delivers synchronously and queues re-entrant events', () {
      final events = DomainEvents();
      final seen = <DomainEvent>[];
      events.stream.listen((e) {
        seen.add(e);
        if (e is StudentsChanged) events.publish(const SessionDataReset());
      });
      events.publish(const StudentsChanged(studentId: 1));
      expect(seen, hasLength(2));
      expect(seen.last, isA<SessionDataReset>());
    });

    test('a closed bus drops events', () async {
      final events = DomainEvents();
      final seen = <DomainEvent>[];
      events.stream.listen(seen.add);
      await events.close();
      events.publish(const SessionDataReset());
      expect(seen, isEmpty);
    });
  });
}
