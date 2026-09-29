import 'package:edusistem_front/features/audit/data/models/audit_log_model.dart';
import 'package:edusistem_front/features/audit/presentation/shared/audit_labels.dart';
import 'package:edusistem_front/features/teaching/data/models/teaching_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TeachingPeriodSummaryModel parses the summary contract', () {
    final summary = TeachingPeriodSummaryModel.fromJson({
      'teachingPeriodId': 30,
      'studentCount': 16,
      'activityCount': 4,
      'examCount': 2,
      'grading': {
        'expectedGrades': 96,
        'registeredGrades': 72,
        'progressPercent': 75,
      },
    });
    expect(summary.teachingPeriodId, 30);
    expect(summary.activityCount, 4);
    expect(summary.examCount, 2);
    expect(summary.registeredGrades, 72);
    expect(summary.expectedGrades, 96);
    expect(summary.progressPercent, 75);
  });

  group('audit log label', () {
    Map<String, dynamic> json({String? entityLabel, int? teachingPeriodId}) => {
      'id': 1,
      'action': 'EXAM_PROCESSED',
      'entityType': 'Submission',
      'entityId': 5,
      'teachingPeriodId': teachingPeriodId,
      'entityLabel': entityLabel,
      'result': 'SUCCESS',
      'details': null,
      'createdAt': '2026-09-28T10:00:00',
    };

    test('uses the backend label and class when present', () {
      final log = AuditLogModel.fromJson(
        json(entityLabel: 'Parcial 1 · Ana Pérez', teachingPeriodId: 30),
      );
      expect(log.teachingPeriodId, 30);
      expect(auditEntityLabel(log), 'Parcial 1 · Ana Pérez');
    });

    test('falls back to "Tipo #id" for entries without a label', () {
      final log = AuditLogModel.fromJson(json());
      expect(log.teachingPeriodId, isNull);
      expect(auditEntityLabel(log), 'Submission #5');
    });
  });
}
