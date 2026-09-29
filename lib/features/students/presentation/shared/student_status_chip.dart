import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/student_entity.dart';

/// "Activo" / "Retirado" for a course enrollment; nothing without one.
class StudentStatusChip extends StatelessWidget {
  const StudentStatusChip({super.key, required this.enrollment});

  final StudentEnrollmentEntity? enrollment;

  @override
  Widget build(BuildContext context) {
    final enrollment = this.enrollment;
    if (enrollment == null) {
      return const AppStatusChip(
        label: 'Sin curso',
        kind: AppStatusKind.neutral,
      );
    }
    return enrollment.active
        ? const AppStatusChip(label: 'Activo', kind: AppStatusKind.success)
        : const AppStatusChip(label: 'Retirado', kind: AppStatusKind.neutral);
  }
}
