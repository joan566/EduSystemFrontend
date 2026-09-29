import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/gradebook_entities.dart';
import '../../domain/entities/grading_entities.dart';

/// "4.78 / 5.00", or "—" without a grade or scale.
String periodGradeLabel(double? grade, GradingScaleEntity? scale) =>
    grade == null || scale == null
    ? '—'
    : Formatters.grade(grade, scale.maximumValue);

/// Where [grade] falls in [scale], 0..1.
double scaleFraction(double grade, GradingScaleEntity scale) =>
    ((grade - scale.minimumValue) / (scale.maximumValue - scale.minimumValue))
        .clamp(0.0, 1.0);

/// A number without trailing zeros: 9 → "9", 9.5 → "9.5", 22.25 → "22.25".
String compactNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// "9.5 / 10" for one evaluation, "Sin nota" without a result.
String entryGradeLabel(GradebookEntry entry) {
  if (entry.excluded) return 'No cuenta';
  final earned = entry.earned;
  return earned == null
      ? 'Sin nota'
      : '${compactNumber(earned)} / ${compactNumber(entry.maximumScore)}';
}

/// "(22.5 pts)": points out of 100 the evaluation adds to the final grade.
String? contributionLabel(GradebookEntry entry) {
  final contribution = entry.contribution;
  return contribution == null ? null : '${compactNumber(contribution)} pts';
}

String weightLabel(double? weight) =>
    weight == null ? '—' : '${compactNumber(weight)}%';

/// "Tarea", "Examen", "Asistencia" — the evaluation's kind as the teacher
/// named it.
String evaluationKindLabel(GradebookEntry entry) => switch (entry.type) {
  EvaluationType.exam => 'Examen',
  EvaluationType.activity =>
    (entry.activityType?.trim().isNotEmpty ?? false)
        ? entry.activityType!.trim()
        : 'Actividad',
  EvaluationType.attendance => 'Asistencia',
};

IconData evaluationIcon(EvaluationType type) => switch (type) {
  EvaluationType.exam => Icons.fact_check_outlined,
  EvaluationType.activity => Icons.assignment_outlined,
  EvaluationType.attendance => Icons.event_available_outlined,
};

/// Aprobado / Reprobado against the class's passing grade; "Sin nota"
/// without a grade; nothing when the class has no passing grade.
class GradeStatusChip extends StatelessWidget {
  const GradeStatusChip({
    super.key,
    required this.passing,
    required this.hasGrade,
  });

  final bool? passing;
  final bool hasGrade;

  @override
  Widget build(BuildContext context) {
    if (!hasGrade) {
      return const AppStatusChip(
        label: 'Sin nota',
        kind: AppStatusKind.neutral,
      );
    }
    return switch (passing) {
      true => const AppStatusChip(
        label: 'Aprobado',
        kind: AppStatusKind.success,
      ),
      false => const AppStatusChip(
        label: 'Reprobado',
        kind: AppStatusKind.error,
      ),
      null => const SizedBox.shrink(),
    };
  }
}
