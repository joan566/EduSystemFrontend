import 'package:edusistem_front/features/teaching/domain/entities/teaching_assignment_entity.dart';
import 'package:edusistem_front/features/teaching/domain/entities/teaching_period_entity.dart';
import 'package:edusistem_front/features/teaching/presentation/shared/class_grouping.dart';
import 'package:edusistem_front/features/teaching/presentation/shared/class_labels.dart';
import 'package:flutter_test/flutter_test.dart';

TeachingAssignmentEntity _assignment(
  int id, {
  required int groupId,
  required String grade,
  String group = 'A',
  int year = 2026,
  int subjectId = 1,
  String subject = 'Matemáticas',
}) => TeachingAssignmentEntity(
  id: id,
  groupId: groupId,
  groupName: group,
  gradeName: grade,
  academicYear: year,
  subjectId: subjectId,
  subjectName: subject,
  active: true,
);

TeachingPeriodEntity _class(
  int id,
  TeachingAssignmentEntity a, {
  int academicPeriodId = 2,
  int students = 30,
}) => TeachingPeriodEntity(
  id: id,
  teachingAssignmentId: a.id,
  groupId: a.groupId,
  groupName: a.groupName,
  gradeName: a.gradeName,
  academicYear: a.academicYear,
  subjectId: a.subjectId,
  subjectName: a.subjectName,
  academicPeriodId: academicPeriodId,
  academicPeriodName: 'Periodo $academicPeriodId',
  startDate: DateTime(2026, academicPeriodId * 3),
  endDate: DateTime(2026, academicPeriodId * 3 + 2),
  studentCount: students,
);

void main() {
  group('courseName', () {
    test('joins grade and group', () {
      expect(courseName('6°', 'A'), '6° A');
    });

    test('does not repeat a grade the group name already carries', () {
      expect(courseName('10°', '10-A'), '10° A');
      expect(courseName('10°', '10A'), '10° A');
      expect(courseName('10°', '10° B'), '10° B');
      expect(courseName('10°', '10'), '10°');
      expect(courseName('Transición', 'Transición A'), 'Transición A');
    });

    test('a longer number is not taken for the grade', () {
      expect(courseName('1°', '10A'), '1° 10A');
    });
  });

  test('courseLabels adds the year only to colliding names', () {
    final labels = courseLabels([
      (groupId: 1, gradeName: '6°', groupName: 'A', academicYear: 2025),
      (groupId: 2, gradeName: '6°', groupName: 'A', academicYear: 2026),
      (groupId: 3, gradeName: '6°', groupName: 'B', academicYear: 2026),
    ]);
    expect(labels, {1: '6° A (2025)', 2: '6° A (2026)', 3: '6° B'});
  });

  test('classLabel shows the period only when it is not the current one', () {
    final a = _assignment(1, groupId: 1, grade: '6°');
    expect(
      classLabel(_class(1, a), currentAcademicPeriodId: 2),
      'Matemáticas · 6° A',
    );
    expect(
      classLabel(_class(1, a), currentAcademicPeriodId: 3),
      'Matemáticas · 6° A (Periodo 2)',
    );
  });

  test('compareGradeNames orders grades naturally', () {
    final grades = ['10°', 'Grado 11', '6°', 'Transición', '7°']
      ..sort(compareGradeNames);
    expect(grades, ['Transición', '6°', '7°', '10°', 'Grado 11']);
  });

  group('groupClasses', () {
    test('case 1: one subject in one course', () {
      final a = _assignment(1, groupId: 1, grade: '6°');
      final grouping = groupClasses(
        assignments: [a],
        periods: [_class(10, a)],
        academicPeriodId: 2,
      );
      expect(grouping.courseCount, 1);
      expect(grouping.classCount, 1);
      expect(grouping.courses.single.entries.single.period?.id, 10);
    });

    test('case 2: one subject in three courses is named once', () {
      final assignments = [
        _assignment(1, groupId: 8, grade: '8°'),
        _assignment(2, groupId: 6, grade: '6°'),
        _assignment(3, groupId: 7, grade: '7°'),
      ];
      final grouping = groupClasses(
        assignments: assignments,
        periods: [for (final a in assignments) _class(a.id * 10, a)],
        academicPeriodId: 2,
      );
      expect(grouping.singleSubjectName, 'Matemáticas');
      expect(
        [for (final c in grouping.courses) c.label],
        ['6° A', '7° A', '8° A'],
      );
    });

    test('case 3: several subjects per course are grouped under it', () {
      final assignments = [
        _assignment(
          1,
          groupId: 1,
          grade: '3°',
          subjectId: 2,
          subject: 'Español',
        ),
        _assignment(2, groupId: 1, grade: '3°'),
        _assignment(3, groupId: 2, grade: '3°', group: 'B'),
        _assignment(
          4,
          groupId: 2,
          grade: '3°',
          group: 'B',
          subjectId: 3,
          subject: 'Ciencias',
        ),
      ];
      final grouping = groupClasses(
        assignments: assignments,
        periods: [for (final a in assignments) _class(a.id * 10, a)],
        academicPeriodId: 2,
      );
      expect(grouping.singleSubjectName, isNull);
      expect(grouping.sections.single.gradeName, '3°');
      final [a, b] = grouping.sections.single.courses;
      expect(a.label, '3° A');
      expect(
        [for (final e in a.entries) e.subjectName],
        ['Español', 'Matemáticas'],
      );
      expect(b.label, '3° B');
      expect(
        [for (final e in b.entries) e.subjectName],
        ['Ciencias', 'Matemáticas'],
      );
    });

    test('case 4: many courses become one section per grade, in order', () {
      final assignments = [
        for (final (i, grade) in ['10°', '6°', '11°', '9°'].indexed)
          for (final group in ['B', 'A'])
            for (final subject in [(1, 'Matemáticas'), (2, 'Estadística')])
              _assignment(
                i * 100 + group.codeUnitAt(0) * 10 + subject.$1,
                groupId: i * 10 + group.codeUnitAt(0),
                grade: grade,
                group: group,
                subjectId: subject.$1,
                subject: subject.$2,
              ),
      ];
      final grouping = groupClasses(
        assignments: assignments,
        periods: [for (final a in assignments) _class(a.id, a)],
        academicPeriodId: 2,
      );
      expect(
        [for (final s in grouping.sections) s.gradeName],
        ['6°', '9°', '10°', '11°'],
      );
      expect(
        [for (final c in grouping.sections.first.courses) c.label],
        ['6° A', '6° B'],
      );
      expect(grouping.courseCount, 8);
      expect(grouping.classCount, 16);
    });

    test('case 5: same name in two years and sibling groups stay apart', () {
      final assignments = [
        _assignment(1, groupId: 1, grade: '6°', year: 2025),
        _assignment(2, groupId: 2, grade: '6°'),
        _assignment(3, groupId: 3, grade: '6°', group: 'B'),
      ];
      final grouping = groupClasses(
        assignments: assignments,
        periods: [for (final a in assignments) _class(a.id * 10, a)],
        academicPeriodId: 2,
      );
      expect(
        [for (final c in grouping.courses) c.label],
        ['6° A (2026)', '6° A (2025)', '6° B'],
      );
    });

    test('a subject without a class in the period stays, with no class', () {
      final withClass = _assignment(1, groupId: 1, grade: '6°');
      final without = _assignment(
        2,
        groupId: 1,
        grade: '6°',
        subjectId: 2,
        subject: 'Estadística',
      );
      final grouping = groupClasses(
        assignments: [withClass, without],
        periods: [
          _class(10, withClass, students: 32),
          _class(20, without, academicPeriodId: 1),
        ],
        academicPeriodId: 2,
      );
      final course = grouping.courses.single;
      expect(course.entries.map((e) => e.period?.id), [null, 10]);
      expect(course.studentCount, 32);
      expect(grouping.classCount, 1);
    });

    test('include filters entries and drops emptied courses', () {
      final assignments = [
        _assignment(1, groupId: 1, grade: '6°'),
        _assignment(
          2,
          groupId: 2,
          grade: '7°',
          subjectId: 2,
          subject: 'Estadística',
        ),
      ];
      final grouping = groupClasses(
        assignments: assignments,
        periods: const [],
        include: (entry, _) => entry.subjectId == 2,
      );
      expect([for (final c in grouping.courses) c.label], ['7° A']);
    });
  });
}
