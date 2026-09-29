import 'package:edusistem_front/features/academic_periods/domain/entities/academic_period_entity.dart';
import 'package:edusistem_front/features/teaching/domain/entities/teaching_assignment_entity.dart';
import 'package:edusistem_front/features/teaching/domain/entities/teaching_period_entity.dart';
import 'package:edusistem_front/features/teaching/presentation/shared/class_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

const _assignment = TeachingAssignmentEntity(
  id: 1,
  groupId: 1,
  groupName: 'A',
  gradeName: '5°',
  academicYear: 2026,
  subjectId: 3,
  subjectName: 'Matemáticas',
  active: true,
);

TeachingPeriodEntity _class(int id, int academicPeriodId, DateTime start) =>
    TeachingPeriodEntity(
      id: id,
      teachingAssignmentId: 1,
      groupId: 1,
      groupName: 'A',
      gradeName: '5°',
      academicYear: 2026,
      subjectId: 3,
      subjectName: 'Matemáticas',
      academicPeriodId: academicPeriodId,
      academicPeriodName: 'P$academicPeriodId',
      startDate: start,
      endDate: start.add(const Duration(days: 120)),
    );

void main() {
  final first = _class(10, 1, DateTime(2026, 1, 15));
  final second = _class(20, 2, DateTime(2026, 7, 1));

  group('classForAssignment', () {
    test('picks the class of the chosen academic period', () {
      expect(
        classForAssignment(_assignment, [first, second], academicPeriodId: 1),
        first,
      );
    });

    test('with no period chosen, picks the most recent class', () {
      expect(classForAssignment(_assignment, [first, second]), second);
    });

    test('is null when the assignment has no class in that period', () {
      expect(
        classForAssignment(_assignment, [first], academicPeriodId: 2),
        isNull,
      );
    });
  });

  test('classPeriodStatus compares today with the class dates', () {
    expect(
      classPeriodStatus(second, DateTime(2026, 6, 30)),
      ClassPeriodStatus.upcoming,
    );
    expect(
      classPeriodStatus(second, DateTime(2026, 7, 1, 9)),
      ClassPeriodStatus.active,
    );
    expect(
      classPeriodStatus(second, DateTime(2027, 1, 1)),
      ClassPeriodStatus.finished,
    );
  });

  test('defaultAcademicPeriod falls back to the most recent one', () {
    final old = AcademicPeriodEntity(
      id: 1,
      name: '2020-1',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2020, 6, 1),
    );
    final newer = AcademicPeriodEntity(
      id: 2,
      name: '2020-2',
      startDate: DateTime(2020, 7, 1),
      endDate: DateTime(2020, 12, 1),
    );
    expect(defaultAcademicPeriod([old, newer]), newer);
    expect(defaultAcademicPeriod([]), isNull);
  });

  test('matchesSearch ignores case and accents', () {
    expect(matchesSearch('matematicas', ['Matemáticas']), isTrue);
    expect(matchesSearch('INGLÉS', ['Inglés — 5° A']), isTrue);
    expect(matchesSearch('5° b', ['Castellano', '5° A']), isFalse);
    expect(matchesSearch('  ', ['cualquiera']), isTrue);
  });
}
