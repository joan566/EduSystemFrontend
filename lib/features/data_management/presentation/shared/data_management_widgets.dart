import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../imports/domain/entities/import_batch_entity.dart';
import '../../../imports/presentation/providers/imports_provider.dart';

class DataTemplateOption extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final Widget? badge;
  final bool isLoading;

  /// Shown under the button only while [onPressed] is null — the reason
  /// it's disabled has to be visible, not just a grayed-out button with no
  /// explanation.
  final String? disabledHint;

  const DataTemplateOption({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.badge,
    this.isLoading = false,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: textTheme.bodySmall),
          const SizedBox(height: 12),
          AppButton(
            label: buttonLabel,
            icon: Icons.download_outlined,
            variant: AppButtonVariant.outlined,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
          if (onPressed == null && disabledHint != null) ...[
            const SizedBox(height: 6),
            Text(
              disabledHint!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class RecommendedChip extends StatelessWidget {
  const RecommendedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Recomendado',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.accentBlue),
      ),
    );
  }
}

class ImportResultSummary extends StatelessWidget {
  const ImportResultSummary({
    super.key,
    required this.result,
    this.onDownloadErrors,
    required this.onDismiss,
  });

  final ImportResultEntity result;
  final VoidCallback? onDownloadErrors;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: batch.failedRows == 0
            ? AppColors.successBg
            : AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${batch.totalRows} filas procesadas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${batch.successfulRows} correctas · ${batch.failedRows} errores',
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Errores', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final error in result.errors.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Fila ${error.row} (${error.column}): ${error.message}',
                ),
              ),
            if (result.errorsTruncated)
              Text(
                'Hay más errores. Descarga el reporte completo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          if (onDownloadErrors != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Descargar reporte de errores',
              icon: Icons.download_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: onDownloadErrors,
            ),
          ],
        ],
      ),
    );
  }
}

class ImportHistoryList extends StatelessWidget {
  const ImportHistoryList({
    super.key,
    required this.state,
    required this.onOpen,
  });

  final ListViewState<ImportBatchEntity> state;

  /// How the current platform presents [ImportBatchDetail] for a batch.
  final ValueChanged<ImportBatchEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const Padding(padding: EdgeInsets.all(24), child: AppLoading());
      case ViewStatus.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorState(
            exception: state.error!,
            onRetry: () => context.read<ImportsProvider>().loadHistory(),
          ),
        );
      case ViewStatus.empty:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: AppEmptyState(
            title: 'Aún no has realizado importaciones',
            message:
                'Cuando subas un archivo Excel, aparecerá aquí junto con su '
                'resultado.',
            icon: Icons.history_outlined,
          ),
        );
      case ViewStatus.success:
        return Column(
          children: [
            for (final batch in state.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: AppListTile(
                  icon: Icons.description_outlined,
                  title: batch.fileName,
                  subtitle:
                      '${Formatters.dateTime(batch.createdAt)} · '
                      '${batch.successfulRows}/${batch.totalRows} correctas',
                  trailing: importStatusChip(batch.status),
                  onTap: () => onOpen(batch),
                ),
              ),
          ],
        );
    }
  }
}

Widget importStatusChip(ImportStatus status) {
  return switch (status) {
    ImportStatus.completed => const AppStatusChip(
      label: 'Completado',
      kind: AppStatusKind.success,
    ),
    ImportStatus.completedWithErrors => const AppStatusChip(
      label: 'Con errores',
      kind: AppStatusKind.warning,
    ),
    ImportStatus.failed => const AppStatusChip(
      label: 'Fallido',
      kind: AppStatusKind.error,
    ),
    ImportStatus.processing => const AppStatusChip(
      label: 'Procesando',
      kind: AppStatusKind.info,
    ),
  };
}

/// Detail content for a single history entry: the counts already shown in the
/// list, plus — for a batch with per-row failures — a way to download the
/// full error report. A batch that failed before any row was even
/// evaluated (bad file type, missing columns) has no report to offer, so it
/// gets an explanatory note instead of a dead-end status chip.
class ImportBatchDetail extends StatefulWidget {
  const ImportBatchDetail({super.key, required this.batch});

  final ImportBatchEntity batch;

  @override
  State<ImportBatchDetail> createState() => _ImportBatchDetailState();
}

class _ImportBatchDetailState extends State<ImportBatchDetail> {
  bool _downloading = false;

  // A batch that failed before any row was evaluated (bad file type,
  // missing columns, too many rows) has no error report — the only place
  // that failure reason survives is the audit trail, so it's fetched
  // separately instead of coming from the batch itself.
  bool _loadingReason = false;
  String? _failureReason;

  @override
  void initState() {
    super.initState();
    if (!widget.batch.hasErrorReport &&
        widget.batch.status == ImportStatus.failed) {
      _loadReason();
    }
  }

  Future<void> _loadReason() async {
    setState(() => _loadingReason = true);
    try {
      final reason = await context.read<ImportsProvider>().getFailureReason(
        widget.batch.id,
      );
      if (mounted) setState(() => _failureReason = reason);
    } catch (_) {
      // Falls back to the generic explanation below.
    } finally {
      if (mounted) setState(() => _loadingReason = false);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    final provider = context.read<ImportsProvider>();
    try {
      await fetchAndSaveFile(
        context,
        fetch: () => provider.downloadErrorReport(widget.batch.id),
        errorMessage: 'No se pudo descargar el reporte.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final textTheme = Theme.of(context).textTheme;

    return AppFormFrame(
      title: batch.fileName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          importStatusChip(batch.status),
          const SizedBox(height: 16),
          _DetailRow(label: 'Filas procesadas', value: '${batch.totalRows}'),
          _DetailRow(label: 'Correctas', value: '${batch.successfulRows}'),
          _DetailRow(label: 'Fallidas', value: '${batch.failedRows}'),
          _DetailRow(
            label: 'Creado',
            value: Formatters.dateTime(batch.createdAt),
          ),
          if (batch.completedAt != null)
            _DetailRow(
              label: 'Completado',
              value: Formatters.dateTime(batch.completedAt!),
            ),
          if (batch.hasErrorReport) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Descargar reporte de errores',
              icon: Icons.download_outlined,
              variant: AppButtonVariant.outlined,
              isLoading: _downloading,
              expand: true,
              onPressed: _download,
            ),
          ] else if (batch.status == ImportStatus.failed) ...[
            const SizedBox(height: 16),
            Text('Motivo', style: textTheme.labelLarge),
            const SizedBox(height: 6),
            if (_loadingReason)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _failureReason ??
                      'El archivo no llegó a procesarse y el servidor no registró un '
                          'motivo específico. Verifica que sea un .xlsx basado en la '
                          'plantilla y que tenga todas las columnas requeridas.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
