import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';

/// Resolves a class's period grades (loaded by the page when the class
/// changes): loading, error, a missing or incomplete configuration (with a
/// way to Configuración de notas) and an empty roster. [builder] only
/// renders real data; the backend is the sole source of the grades.
/// [placeholder] is the platform's skeleton of that data while it loads.
class PeriodGradesStateView extends StatelessWidget {
  const PeriodGradesStateView({
    super.key,
    required this.teachingPeriodId,
    required this.builder,
    required this.placeholder,
  });

  final int teachingPeriodId;
  final Widget Function(BuildContext context, PeriodGradesEntity data) builder;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradingProvider>().periodGrades(
      teachingPeriodId,
    );

    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return placeholder;
      case DetailStatus.error:
        final error = state.error!;
        final missing = error.code == 'GRADING_CONFIGURATION_REQUIRED';
        if (missing || error.code == 'GRADING_CONFIGURATION_INCOMPLETE') {
          return AppEmptyState(
            title: missing
                ? 'Esta clase aún no tiene pesos de evaluación'
                : 'Los pesos de evaluación no suman 100%',
            message:
                'Define la escala y cuánto pesa cada componente para calcular '
                'las notas.',
            icon: Icons.tune,
            actionLabel: 'Configurar pesos',
            // Saving the weights there makes these grades stale, so they
            // are re-read on return.
            onAction: () => context.push(
              RoutePaths.gradingSettingsForClass(teachingPeriodId),
            ),
          );
        }
        return AppErrorState(
          exception: error,
          onRetry: () => context.read<GradingProvider>().refreshPeriodGrades(
            teachingPeriodId,
          ),
        );
      case DetailStatus.success:
        final data = state.data!;
        if (data.students.isEmpty) {
          return const AppEmptyState(
            title: 'No hay estudiantes en este curso',
            icon: Icons.people_alt_outlined,
          );
        }
        return builder(context, data);
    }
  }
}
