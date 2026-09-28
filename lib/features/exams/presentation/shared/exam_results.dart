import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/submissions_provider.dart';
import 'exam_actions.dart';

/// Loads an exam's submissions (§51) and resolves loading/error/empty;
/// [builder] renders the real listing, differently per platform.
class ExamResultsStateView extends StatefulWidget {
  const ExamResultsStateView({
    super.key,
    required this.exam,
    required this.builder,
  });

  final ExamEntity exam;
  final Widget Function(
    BuildContext context,
    ListViewState<SubmissionSummaryEntity> state,
  )
  builder;

  @override
  State<ExamResultsStateView> createState() => _ExamResultsStateViewState();
}

class _ExamResultsStateViewState extends State<ExamResultsStateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SubmissionsProvider>().load(widget.exam.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionsProvider>().state;
    final exam = widget.exam;

    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<SubmissionsProvider>().load(exam.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'Sin resultados todavía',
          message:
              'Escanea una hoja o sube un PDF con todas las hojas para ver resultados aquí.',
          icon: Icons.fact_check_outlined,
          actionLabel: exam.ready ? 'Escanear hoja' : null,
          onAction: exam.ready
              ? () => ExamActions.openScanning(context, exam.id)
              : null,
        );
      case ViewStatus.success:
        return widget.builder(context, state);
    }
  }
}

String submissionGradeLabel(SubmissionSummaryEntity item, ExamEntity exam) =>
    item.finalGrade != null && exam.maximumScore != null
    ? Formatters.grade(item.finalGrade!, exam.maximumScore!)
    : '—';

Widget submissionStatusChip(SubmissionStatus status) {
  return switch (status) {
    SubmissionStatus.processed => const AppStatusChip(
      label: 'Procesado',
      kind: AppStatusKind.success,
    ),
    SubmissionStatus.reviewRequired => const AppStatusChip(
      label: 'Requiere revisión',
      kind: AppStatusKind.warning,
    ),
    SubmissionStatus.pending => const AppStatusChip(
      label: 'Pendiente',
      kind: AppStatusKind.neutral,
    ),
    SubmissionStatus.processing => const AppStatusChip(
      label: 'Procesando',
      kind: AppStatusKind.info,
    ),
    SubmissionStatus.failed => const AppStatusChip(
      label: 'Falló',
      kind: AppStatusKind.error,
    ),
  };
}
