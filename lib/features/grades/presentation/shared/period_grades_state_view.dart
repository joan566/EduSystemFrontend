import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../domain/entities/grading_entities.dart';
import '../providers/grading_provider.dart';

/// Loads the computed period grades (§53, §84) every time the tab is shown
/// — so they reflect a configuration just saved in the other tab — and
/// resolves loading/error/empty. [builder] only renders real data; the
/// backend is the sole source of the official grade.
class PeriodGradesStateView extends StatefulWidget {
  const PeriodGradesStateView({
    super.key,
    required this.teachingPeriodId,
    required this.builder,
  });

  final int teachingPeriodId;
  final Widget Function(BuildContext context, PeriodGradesEntity data) builder;

  @override
  State<PeriodGradesStateView> createState() => _PeriodGradesStateViewState();
}

class _PeriodGradesStateViewState extends State<PeriodGradesStateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GradingProvider>().loadPeriodGrades(
        widget.teachingPeriodId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GradingProvider>().periodGradesState;

    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        final error = state.error!;
        if (error.code == 'GRADING_CONFIGURATION_INCOMPLETE') {
          return const AppEmptyState(
            title: 'La configuración de calificación está incompleta',
            message:
                'Ve a la pestaña "Configuración" y asegúrate de que las '
                'ponderaciones sumen 100%.',
            icon: Icons.rule_outlined,
          );
        }
        return AppErrorState(
          exception: error,
          onRetry: () => context.read<GradingProvider>().loadPeriodGrades(
            widget.teachingPeriodId,
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
        return widget.builder(context, data);
    }
  }
}
