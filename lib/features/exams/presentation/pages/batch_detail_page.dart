import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/submission_batch_entity.dart';
import '../providers/submission_batches_provider.dart';
import '../widgets/batch_labels.dart';

/// Progress and results of one PDF batch. Polls while the batch runs;
/// pages appear as they are resolved. Grades are read fresh on every
/// poll, so manual corrections show up here too.
class BatchDetailPage extends StatefulWidget {
  const BatchDetailPage({
    super.key,
    required this.examId,
    required this.batchId,
  });

  final int examId;
  final int batchId;

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> {
  late final SubmissionBatchesProvider _provider;
  bool _showSkipped = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SubmissionBatchesProvider>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _provider.watch(widget.examId, widget.batchId),
    );
  }

  @override
  void dispose() {
    _provider.stopWatching();
    super.dispose();
  }

  /// Returning from a review or a photo re-upload re-reads the batch so
  /// the corrected grade and averages show up.
  Future<void> _pushAndRefresh(String location) async {
    await context.push(location);
    if (mounted) _provider.watch(widget.examId, widget.batchId);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubmissionBatchesProvider>().detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.data?.batch.fileName ?? 'Lote de hojas'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(DetailViewState<SubmissionBatchEntity> state) {
    switch (state.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => _provider.watch(widget.examId, widget.batchId),
        );
      case DetailStatus.success:
        final data = state.data!;
        final pages = _showSkipped
            ? data.pages
            : data.pages
                  .where((p) => p.outcome != BatchPageOutcome.skipped)
                  .toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _StatusCard(batch: data.batch),
                const SizedBox(height: 16),
                _ResultsSummary(results: data.results),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Páginas',
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    if (data.results.skipped > 0)
                      FilterChip(
                        label: Text('Omitidas (${data.results.skipped})'),
                        selected: _showSkipped,
                        onSelected: (value) =>
                            setState(() => _showSkipped = value),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pages.isEmpty)
                  Text(
                    data.batch.isFinished
                        ? 'Ninguna página contenía una hoja de respuestas.'
                        : 'Las páginas aparecerán aquí a medida que se califiquen.',
                    style: context.textStyles.bodySmall,
                  ),
                for (final page in pages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PageTile(
                      page: page,
                      onReview: page.submission == null
                          ? null
                          : () => _pushAndRefresh(
                              RoutePaths.submissionDetail(
                                widget.examId,
                                page.submission!.id,
                              ),
                            ),
                      onRetryAsPhoto: BatchLabels.canRetryAsPhoto(page)
                          ? () => _pushAndRefresh(
                              RoutePaths.examScanning(widget.examId),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.batch});

  final SubmissionBatchSummaryEntity batch;

  @override
  Widget build(BuildContext context) {
    final running = !batch.isFinished;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  running
                      ? 'Calificando ${batch.processedPages} de ${batch.totalPages} páginas'
                      : '${batch.totalPages} páginas',
                  style: context.textStyles.titleMedium,
                ),
              ),
              BatchLabels.batchStatusChip(batch.status),
            ],
          ),
          if (running) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: batch.status == SubmissionBatchStatus.queued
                  ? null
                  : batch.progressPercent / 100,
            ),
            const SizedBox(height: 8),
            Text(
              batch.status == SubmissionBatchStatus.queued
                  ? 'En cola: empezará en cuanto termine otro PDF.'
                  : '${batch.progressPercent}% · Puedes cerrar esta pantalla, la calificación continúa.',
              style: context.textStyles.bodySmall,
            ),
          ],
          if (batch.status == SubmissionBatchStatus.failed) ...[
            const SizedBox(height: 12),
            Text(
              'El procesamiento se detuvo. Las páginas calificadas antes del fallo se conservan; '
              'puedes volver a subir el PDF.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            if (batch.statusDetail != null) ...[
              const SizedBox(height: 4),
              Text(batch.statusDetail!, style: context.textStyles.bodySmall),
            ],
          ],
          if (batch.replaceExisting || batch.filePurgedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (batch.replaceExisting) 'Reemplaza resultados existentes',
                if (batch.filePurgedAt != null)
                  'PDF original eliminado el ${Formatters.date(batch.filePurgedAt!)}',
              ].join(' · '),
              style: context.textStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.results});

  final BatchResults results;

  @override
  Widget build(BuildContext context) {
    String grade(double? value) => value?.toStringAsFixed(2) ?? '—';

    final items = <(String, String, Color)>[
      ('Calificadas', '${results.graded}', AppColors.success),
      ('Por revisar', '${results.reviewRequired}', AppColors.warning),
      ('Fallidas o rechazadas', '${results.failed + results.rejected}', AppColors.error),
      ('Nota promedio', grade(results.averageFinalGrade), AppColors.primary),
      ('Nota más alta', grade(results.highestFinalGrade), AppColors.primary),
      ('Nota más baja', grade(results.lowestFinalGrade), AppColors.primary),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (label, value, color) in items)
          SizedBox(
            width: 180,
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: context.textStyles.headlineSmall?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.onReview,
    required this.onRetryAsPhoto,
  });

  final BatchPage page;
  final VoidCallback? onReview;
  final VoidCallback? onRetryAsPhoto;

  @override
  Widget build(BuildContext context) {
    final submission = page.submission;
    final title = submission == null
        ? 'Página ${page.page}'
        : 'Página ${page.page} · ${submission.studentName}';

    final String subtitle = switch (page.outcome) {
      BatchPageOutcome.processed || BatchPageOutcome.reviewRequired =>
        submission?.finalGrade == null
            ? 'Sin nota'
            : 'Nota ${submission!.finalGrade!.toStringAsFixed(2)}'
                  '${page.outcome == BatchPageOutcome.reviewRequired ? ' (provisional)' : ''}',
      BatchPageOutcome.failed =>
        'Se identificó al estudiante, pero no se pudo leer la hoja. Súbela como foto.',
      BatchPageOutcome.rejected => BatchLabels.pageError(page.errorCode),
      BatchPageOutcome.skipped => 'No es una hoja de respuestas.',
    };

    final color = switch (page.outcome) {
      BatchPageOutcome.processed => AppColors.success,
      BatchPageOutcome.reviewRequired => AppColors.warning,
      BatchPageOutcome.failed || BatchPageOutcome.rejected => AppColors.error,
      BatchPageOutcome.skipped => AppColors.textDisabled,
    };

    final action = page.outcome == BatchPageOutcome.reviewRequired
        ? AppButton(
            label: 'Revisar',
            variant: AppButtonVariant.outlined,
            onPressed: onReview,
          )
        : onRetryAsPhoto != null
        ? AppButton(
            label: 'Subir foto',
            variant: AppButtonVariant.outlined,
            onPressed: onRetryAsPhoto,
          )
        : null;

    return AppListTile(
      icon: BatchLabels.outcomeIcon(page.outcome),
      iconColor: color,
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 2,
      onTap: onReview,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!context.isMobile) BatchLabels.outcomeChip(page.outcome),
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}
