import 'package:edusistem_front/core/events/domain_events.dart';
import 'package:edusistem_front/core/utils/formatters.dart';
import 'package:edusistem_front/features/academic_periods/data/datasources/academic_period_remote_datasource.dart';
import 'package:edusistem_front/features/academic_periods/data/repositories/academic_period_repository.dart';
import 'package:edusistem_front/features/academic_periods/presentation/providers/academic_periods_provider.dart';
import 'package:edusistem_front/features/teaching/data/datasources/teaching_remote_datasource.dart';
import 'package:edusistem_front/features/teaching/data/repositories/teaching_repository.dart';
import 'package:edusistem_front/features/teaching/presentation/desktop/class_picker_field.dart';
import 'package:edusistem_front/features/teaching/presentation/providers/teaching_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_backend.dart';

Map<String, Object?> _academicPeriod(int id, DateTime start, DateTime end) => {
  'id': id,
  'name': 'Periodo $id',
  'startDate': Formatters.toApiDate(start),
  'endDate': Formatters.toApiDate(end),
};

Map<String, Object?> _class(
  int id, {
  required int groupId,
  required String grade,
  required int subjectId,
  required String subject,
  int academicPeriodId = 2,
}) => {
  ...periodJson(id, groupId: groupId),
  'teachingAssignmentId': id,
  'gradeName': grade,
  'subjectId': subjectId,
  'subjectName': subject,
  'academicPeriodId': academicPeriodId,
  'academicPeriodName': 'Periodo $academicPeriodId',
};

void main() {
  late FakeBackend backend;
  late TeachingProvider teaching;
  late AcademicPeriodsProvider academicPeriods;

  void serve(List<Map<String, Object?>> classes) {
    final now = DateTime.now();
    backend.on(
      'GET',
      '/academic-periods',
      (r) => pageOf([
        _academicPeriod(
          1,
          now.subtract(const Duration(days: 400)),
          now.subtract(const Duration(days: 200)),
        ),
        _academicPeriod(
          2,
          now.subtract(const Duration(days: 30)),
          now.add(const Duration(days: 60)),
        ),
      ], r),
    );
    backend.on('GET', '/teaching-periods', (r) => pageOf(classes, r));
  }

  setUp(() {
    backend = FakeBackend();
    final events = DomainEvents();
    teaching = TeachingProvider(
      TeachingRepository(TeachingRemoteDataSource(backend.client())),
      events,
    );
    academicPeriods = AcademicPeriodsProvider(
      AcademicPeriodRepository(
        AcademicPeriodRemoteDataSource(backend.client()),
      ),
      events,
    );
  });

  /// Opens the desktop class picker over an empty app.
  Future<void> open(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: teaching),
          ChangeNotifierProvider.value(value: academicPeriods),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    showDesktopClassPicker(context, selected: null);
    await tester.pumpAndSettle();
  }

  testWidgets('lists the running period by course, subjects inside', (
    tester,
  ) async {
    serve([
      _class(1, groupId: 7, grade: '7°', subjectId: 1, subject: 'Matemáticas'),
      _class(2, groupId: 6, grade: '6°', subjectId: 2, subject: 'Estadística'),
      _class(3, groupId: 6, grade: '6°', subjectId: 1, subject: 'Matemáticas'),
      _class(
        4,
        groupId: 6,
        grade: '6°',
        subjectId: 1,
        subject: 'Matemáticas',
        academicPeriodId: 1,
      ),
    ]);
    await open(tester);

    // Course headers in grade order, subjects under them.
    expect(find.text('6° A'), findsOneWidget);
    expect(find.text('7° A'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('6° A')).dy,
      lessThan(tester.getTopLeft(find.text('7° A')).dy),
    );
    expect(find.text('Matemáticas'), findsNWidgets(2));
    // The old period's class only shows with "Todos los periodos".
    expect(find.textContaining('Periodo 1'), findsNothing);
    await tester.tap(find.text('Todos los periodos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Periodo 1 · '), findsOneWidget);

    await tester.tap(find.text('Estadística'));
    await tester.pumpAndSettle();
    expect(teaching.lastClassId, 2);
  });

  testWidgets('one subject in several courses is named once', (tester) async {
    serve([
      for (final (i, grade) in ['8°', '6°', '7°'].indexed)
        _class(
          i + 1,
          groupId: i + 1,
          grade: grade,
          subjectId: 1,
          subject: 'Matemáticas',
        ),
    ]);
    await open(tester);

    expect(find.text('Matemáticas · 3 cursos'), findsOneWidget);
    expect(find.text('Matemáticas'), findsNothing);
    expect(find.text('6° A'), findsOneWidget);
  });
}
