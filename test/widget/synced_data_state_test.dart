import 'package:edusistem_front/core/cache/synced_data_state.dart';
import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/router/shell_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.calls});

  final List<String> calls;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with SyncedDataState<_Probe> {
  @override
  void ensureData() => widget.calls.add('ensure');

  @override
  Widget build(BuildContext context) => const Text('list');
}

void main() {
  testWidgets('ensures on entry, on return and after events; never while '
      'covered or from build', (tester) async {
    final events = DomainEvents();
    final calls = <String>[];
    final router = GoRouter(
      routes: [
        ShellRoute(
          observers: [shellRouteObserver],
          builder: (context, state, child) => child,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => _Probe(calls: calls),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, _) => const Text('detail'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      Provider<DomainEvents>.value(
        value: events,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, hasLength(1), reason: 'entering');

    // Rebuilds never fetch.
    await tester.pump();
    await tester.pump();
    expect(calls, hasLength(1));

    // A mutation elsewhere while visible: ensure once (fresh data is a
    // no-op inside ensure).
    events.publish(const StudentsChanged());
    events.publish(const StudentsChanged());
    await tester.pump();
    expect(calls, hasLength(2), reason: 'events in one frame coalesce');

    // Covered by another page: events don't trigger it...
    router.push('/detail');
    await tester.pumpAndSettle();
    events.publish(const StudentsChanged());
    await tester.pump();
    expect(calls, hasLength(2));

    // ...coming back does.
    router.pop();
    await tester.pumpAndSettle();
    expect(calls, hasLength(3), reason: 'volver');
    await events.close();
  });
}
