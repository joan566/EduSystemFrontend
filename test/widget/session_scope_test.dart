import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/session/session_scope.dart';
import 'package:edusistem_front/features/subjects/data/datasources/subject_remote_datasource.dart';
import 'package:edusistem_front/features/subjects/data/repositories/subject_repository.dart';
import 'package:edusistem_front/features/subjects/presentation/providers/subjects_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late ApiClient api;

  /// Which teacher the backend answers for (it authorizes by token; the
  /// test just switches what it returns).
  late String teacher;

  late ValueNotifier<int?> userId;
  late List<SubjectsProvider> sessions;
  late List<GoRouter> routers;
  SubjectsProvider? shown;

  setUp(() {
    backend = FakeBackend();
    api = backend.client();
    teacher = 'A';
    backend.on(
      'GET',
      '/subjects',
      (r) => pageOf([subjectJson(teacher == 'A' ? 1 : 2, 'De $teacher')], r),
    );
    userId = ValueNotifier<int?>(1);
    sessions = [];
    routers = [];
    shown = null;
  });

  Widget app() => ValueListenableBuilder<int?>(
    valueListenable: userId,
    builder: (context, id, _) => SessionScope(
      key: ValueKey<int?>(id),
      providers: () => [
        ChangeNotifierProvider<SubjectsProvider>(
          create: (context) {
            final provider = SubjectsProvider(
              SubjectRepository(SubjectRemoteDataSource(api)),
              context.read<DomainEvents>(),
            );
            sessions.add(provider);
            return provider;
          },
        ),
      ],
      createRouter: () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) {
                shown = context.watch<SubjectsProvider>();
                return const SizedBox();
              },
            ),
          ],
        );
        routers.add(router);
        return router;
      },
      builder: (context, router) => MaterialApp.router(routerConfig: router),
    ),
  );

  Future<void> signIn(WidgetTester tester, int? id, String who) async {
    teacher = who;
    userId.value = id;
    await tester.pumpAndSettle();
  }

  testWidgets('teacher B never sees teacher A data', (tester) async {
    await tester.pumpWidget(app());
    final a = shown!;
    await tester.runAsync(a.ensure);
    await tester.pump();
    expect(a.all.single.name, 'De A');

    // A logs out (no user), then B signs in.
    await signIn(tester, null, 'B');
    expect(a.isDisposed, isTrue, reason: "A's session is destroyed");
    await signIn(tester, 2, 'B');

    final b = shown!;
    expect(identical(a, b), isFalse);
    expect(b.all, isEmpty, reason: 'B starts empty, nothing carried over');
    await tester.runAsync(b.ensure);
    await tester.pump();
    expect(b.all.single.name, 'De B');
    expect(b.all.any((s) => s.name == 'De A'), isFalse);

    // Every session had its own providers and its own navigation stack.
    expect(sessions, hasLength(3));
    expect(routers.toSet(), hasLength(3));
  });

  testWidgets('a late response of A does not reach B', (tester) async {
    await tester.pumpWidget(app());
    final a = shown!;
    final gate = backend.hold('GET', '/subjects');
    late Future<void> pending;
    await tester.runAsync(() async {
      pending = a.ensure();
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });

    await signIn(tester, 2, 'B');
    final b = shown!;

    // A's request answers now, after the switch.
    await tester.runAsync(() async {
      gate.complete();
      await pending;
    });
    await tester.pump();

    expect(a.all, isEmpty, reason: 'the disposed provider stores nothing');
    expect(b.all, isEmpty, reason: "B's cache was never written by A");
    expect(tester.takeException(), isNull);
  });

  testWidgets('the same teacher signing in again starts clean', (tester) async {
    await tester.pumpWidget(app());
    final first = shown!;
    await tester.runAsync(first.ensure);
    await signIn(tester, null, 'A');
    await signIn(tester, 1, 'A');
    expect(identical(first, shown), isFalse);
    expect(shown!.all, isEmpty);
  });
}
