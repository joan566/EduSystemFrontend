import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../domain/entities/submission_batch_entity.dart';
import 'batch_labels.dart';

class BatchStatusCard extends StatelessWidget {
  const BatchStatusCard({super.key, required this.batch});

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

/// Label, value and accent color of each batch result figure.
List<(String, String, Color)> batchResultItems(BatchResults results) {
  String grade(double? value) => value?.toStringAsFixed(2) ?? '—';
  return [
    ('Calificadas', '${results.graded}', AppColors.success),
    ('Por revisar', '${results.reviewRequired}', AppColors.warning),
    (
      'Fallidas o rechazadas',
      '${results.failed + results.rejected}',
      AppColors.error,
    ),
    ('Nota promedio', grade(results.averageFinalGrade), AppColors.accentBlue),
    ('Nota más alta', grade(results.highestFinalGrade), AppColors.accentBlue),
    ('Nota más baja', grade(results.lowestFinalGrade), AppColors.accentBlue),
  ];
}

/// One result figure in a small card.
class BatchResultFigure extends StatelessWidget {
  const BatchResultFigure({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textStyles.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class BatchPageTile extends StatelessWidget {
  const BatchPageTile({
    super.key,
    required this.page,
    required this.onReview,
    required this.onRetryAsPhoto,
    required this.showOutcomeChip,
  });

  final BatchPage page;
  final VoidCallback? onReview;
  final VoidCallback? onRetryAsPhoto;

  /// Desktop shows the outcome as a chip too; on a phone the colored icon
  /// alone carries it, leaving room for the action button.
  final bool showOutcomeChip;

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
          if (showOutcomeChip) BatchLabels.outcomeChip(page.outcome),
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}

/// What both batch-detail views get from the page: the skipped-pages
/// filter and navigation that re-reads the batch on return.
class BatchDetailViewProps {
  const BatchDetailViewProps({
    required this.examId,
    required this.showSkipped,
    required this.onShowSkippedChanged,
    required this.onRetry,
    required this.onNavigate,
  });

  final int examId;
  final bool showSkipped;
  final ValueChanged<bool> onShowSkippedChanged;
  final VoidCallback onRetry;
  final Future<void> Function(String location) onNavigate;
}

/// "Páginas" heading with the skipped-pages filter, then one tile per page.
class BatchPagesList extends StatelessWidget {
  const BatchPagesList({
    super.key,
    required this.data,
    required this.props,
    required this.showOutcomeChip,
  });

  final SubmissionBatchEntity data;
  final BatchDetailViewProps props;
  final bool showOutcomeChip;

  @override
  Widget build(BuildContext context) {
    final pages = props.showSkipped
        ? data.pages
        : data.pages
              .where((p) => p.outcome != BatchPageOutcome.skipped)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Páginas', style: context.textStyles.titleMedium),
            ),
            if (data.results.skipped > 0)
              FilterChip(
                label: Text('Omitidas (${data.results.skipped})'),
                selected: props.showSkipped,
                onSelected: props.onShowSkippedChanged,
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
            child: BatchPageTile(
              page: page,
              showOutcomeChip: showOutcomeChip,
              onReview: page.submission == null
                  ? null
                  : () => props.onNavigate(
                      RoutePaths.submissionDetail(
                        props.examId,
                        page.submission!.id,
                      ),
                    ),
              onRetryAsPhoto: BatchLabels.canRetryAsPhoto(page)
                  ? () =>
                        props.onNavigate(RoutePaths.examScanning(props.examId))
                  : null,
            ),
          ),
      ],
    );
  }
}
