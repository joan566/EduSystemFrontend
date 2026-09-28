import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/submission_entity.dart';
import '../providers/submissions_provider.dart';

/// Submission listing + review entry point (§51). Scanning a new sheet is
/// reached from here, since results and scanning share the same context
/// (an exam's group of students).
class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key, required this.exam});

  final ExamEntity exam;

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SubmissionsProvider>().load(widget.exam.id),
    );
  }

  /// Batch grading adds submissions in the background, so the listing is
  /// re-read on return.
  Future<void> _openBatches() async {
    await context.push(RoutePaths.submissionBatches(widget.exam.id));
    if (mounted) context.read<SubmissionsProvider>().load(widget.exam.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionsProvider>().state;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              AppButton(
                label: 'Calificar PDF',
                icon: Icons.picture_as_pdf_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: widget.exam.ready ? _openBatches : null,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Escanear hoja',
                icon: Icons.document_scanner_outlined,
                onPressed: widget.exam.ready
                    ? () =>
                          context.push(RoutePaths.examScanning(widget.exam.id))
                    : null,
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context, state)),
        if (state.status == ViewStatus.success)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${state.totalElements} hojas procesadas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<SubmissionSummaryEntity> state,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () =>
              context.read<SubmissionsProvider>().load(widget.exam.id),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'Sin resultados todavía',
          message:
              'Escanea una hoja o sube un PDF con todas las hojas para ver resultados aquí.',
          icon: Icons.fact_check_outlined,
          actionLabel: widget.exam.ready ? 'Escanear hoja' : null,
          onAction: widget.exam.ready
              ? () => context.push(RoutePaths.examScanning(widget.exam.id))
              : null,
        );
      case ViewStatus.success:
        return AppDataTable<SubmissionSummaryEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => context.push(
            RoutePaths.submissionDetail(widget.exam.id, item.id),
          ),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.fact_check_outlined,
            title: item.studentName,
            subtitle:
                item.finalGrade != null && widget.exam.maximumScore != null
                ? Formatters.grade(item.finalGrade!, widget.exam.maximumScore!)
                : item.statusDetail ?? '',
            trailing: _statusChip(item.status),
            onTap: () => context.push(
              RoutePaths.submissionDetail(widget.exam.id, item.id),
            ),
          ),
          columns: [
            AppDataColumn(
              label: 'Estudiante',
              cellBuilder: (item) => Text(item.studentName),
            ),
            AppDataColumn(
              label: 'Calificación',
              cellBuilder: (item) => Text(
                item.finalGrade != null && widget.exam.maximumScore != null
                    ? Formatters.grade(
                        item.finalGrade!,
                        widget.exam.maximumScore!,
                      )
                    : '—',
              ),
            ),
            AppDataColumn(
              label: 'Estado',
              cellBuilder: (item) => _statusChip(item.status),
            ),
          ],
        );
    }
  }

  Widget _statusChip(SubmissionStatus status) {
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
}
