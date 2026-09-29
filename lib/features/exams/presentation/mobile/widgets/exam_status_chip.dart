import 'package:flutter/material.dart';

import '../../../../../core/widgets/shared/app_status_chip.dart';

/// The exam's readiness: "Listo" once every question is configured,
/// "Incompleto" otherwise.
class ExamStatusChip extends StatelessWidget {
  const ExamStatusChip({super.key, required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) => AppStatusChip(
    label: ready ? 'Listo' : 'Incompleto',
    kind: ready ? AppStatusKind.success : AppStatusKind.warning,
  );
}
