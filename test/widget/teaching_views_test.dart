import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/utils/formatters.dart';
import 'package:edusistem_front/features/auth/domain/repositories/auth_repository.dart';
import 'package:edusistem_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:edusistem_front/features/teaching/presentation/desktop/teaching_desktop_view.dart';
import 'package:edusistem_front/features/teaching/presentation/mobile/teaching_mobile_view.dart';
import 'package:edusistem_front/features/teaching/presentation/shared/teaching_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_backend.dart';
import '../helpers/session_fixture.dart';

Map<String, Object?> _assignment(
  int id, {
  required int groupId,
  required String grade,
  required int subjectId,
  required String subject,
  bool active = true,
}) => {
  ...assignmentJson(id, active: active),
  'groupId': groupId,
  'groupName': 'A',
  'gradeName': grade,
  'subjectId': subjectId,
  'subjectName': subject,
};

Map<String, Object?> _class(int id, Map<String, Object?> assignment) => {
  ...periodJson(id),
  'teachingAssignmentId': assignment['id'],
  'groupId': assignment['groupId'],
  'gradeName': assignment['gradeName'],
  'subjectId': assignment['subjectId'],
  'subjectName': assignment['subjectName'],
  'academicPeriodId': 2,
  'academicPeriodName': 'Periodo 2',
};

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SessionFixture s;

  setUp(() async {
    final backend = FakeBackend();
    final now = DateTime.now();
    final assignments = [
      _assignment(
        1,
        groupId: 6,
        grade: '6°',
        subjectId: 1,
        subject: 'Matemáticas',
      ),
      _assignment(
        2,
        groupId: 6,
        grade: '6°',
        subjectId: 2,
        subject: 'Estadística',
      ),
      _assignment(
        3,
        groupId: 10,
        grade: '10°',
        subjectId: 1,
        subject: 'Matemáticas',
        active: false,
      ),
      _assignment(
        4,
        groupId: 7,
        grade: '7°',
        subjectId: 1,
        subject: 'Matemáticas',
      ),
    ];
    backend
      ..on('GET', '/teaching-assignments', (r) => pageOf(assignments, r))
      ..on(
        'GET',
        '/teaching-periods',
        (r) => pageOf([
          _class(11, assignments[0]),
          _class(12, assignments[1]),
          _class(13, assignments[2]),
        ], r),
      )
      ..on(
        'GET',
        '/academic-periods',
        (r) => pageOf([
          {
            'id': 2,
            'name': 'Periodo 2',
            'startDate': Formatters.toApiDate(
              now.subtract(const Duration(days: 30)),
            ),
            'endDate': Formatters.toApiDate(now.add(const Duration(days: 60))),
          },
        ], r),
      )
      ..on(
        'GET',
        '/subjects',
        (r) => pageOf([
          subjectJson(1, 'Matemáticas'),
          subjectJson(2, 'Estadística'),
        ], r),
      );
    s = SessionFixture(backend)..createAll();
    await Future.wait([
      s.teaching.ensureAssignments(),
      s.teaching.ensureAllPeriodsLoaded(),
      s.academicPeriods.ensure(),
      s.subjects.ensure(),
    ]);
  });

  Future<void> pump(WidgetTester tester, Size size, Widget view) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // The brand bar greets the signed-in teacher (none here).
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              repository: _MockAuthRepository(),
              apiClient: ApiClient(onSessionExpired: () async {}),
            ),
          ),
          ChangeNotifierProvider.value(value: s.teaching),
          ChangeNotifierProvider.value(value: s.academicPeriods),
          ChangeNotifierProvider.value(value: s.subjects),
          ChangeNotifierProvider.value(value: s.schedule),
        ],
        child: MaterialApp(home: view),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile: courses in grade order, subjects inside', (
    tester,
  ) async {
    await pump(
      tester,
      const Size(390, 844),
      TeachingMobileView(
        filters: const AssignmentFilters(),
        onFiltersChanged: (_) {},
        academicPeriodId: 2,
        onAcademicPeriodChanged: (_) {},
        search: '',
        onSearchChanged: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('3 cursos  ·  3 clases'), findsOneWidget);
    final y = [
      for (final label in ['6° A', '7° A', '10° A'])
        tester.getTopLeft(find.textContaining(label).first).dy,
    ];
    expect(y, orderedEquals([...y]..sort()));
    expect(find.text('Sin clase en Periodo 2'), findsOneWidget);
    expect(find.text('Inactiva'), findsOneWidget);
  });

  testWidgets('desktop: a header row per course over its subjects', (
    tester,
  ) async {
    await pump(
      tester,
      const Size(1280, 800),
      TeachingDesktopView(
        filters: const AssignmentFilters(),
        onFiltersChanged: (_) {},
        academicPeriodId: 2,
        onAcademicPeriodChanged: (_) {},
        search: '',
        onSearchChanged: (_) {},
        selectedAssignmentId: null,
        onSelect: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('6° A'), findsOneWidget);
    expect(find.text('Estadística'), findsWidgets);
    expect(find.text('Crear clase'), findsOneWidget);
  });

  testWidgets('one subject: each course is a row, the subject named once', (
    tester,
  ) async {
    await pump(
      tester,
      const Size(390, 844),
      TeachingMobileView(
        filters: const AssignmentFilters(subjectId: 1),
        onFiltersChanged: (_) {},
        academicPeriodId: 2,
        onAcademicPeriodChanged: (_) {},
        search: '',
        onSearchChanged: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Matemáticas  ·  3 cursos'), findsOneWidget);
    expect(find.text('6° A'), findsOneWidget);
  });
}
