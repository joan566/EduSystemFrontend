import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_async_button.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../core/widgets/shared/skeleton/skeleton.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
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

/// An upload being sent or processed in the background. The screen stays
/// usable and can be left; the result shows up when it finishes.
class ImportProgressPanel extends StatelessWidget {
  const ImportProgressPanel({super.key, required this.run});

  final ImportRun run;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fileName = run.batch?.fileName;
    final (label, value) = switch (run.phase) {
      ImportPhase.uploading => ('Subiendo archivo…', run.uploadProgress),
      ImportPhase.queued => ('En cola…', null),
      _ => ('Importando…', null),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fileName != null) ...[
            Text(
              fileName,
              style: textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          AppProgressBar(value: value, label: label),
          const SizedBox(height: 10),
          Text(
            'Puedes salir de esta pantalla; la importación sigue en el '
            'servidor.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// An upload that is no longer followed before it finished: polling hit
/// its limit or its state couldn't be read. The history has the outcome.
class ImportUnresolvedNotice extends StatelessWidget {
  const ImportUnresolvedNotice({
    super.key,
    required this.run,
    required this.onDismiss,
  });

  final ImportRun run;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = run.phase == ImportPhase.timedOut
        ? 'La importación sigue en proceso; revisa el historial más tarde.'
        : 'No pudimos consultar el estado de la importación; revisa el '
              'historial.';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
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

  /// How many row errors are listed here; the rest are in the report.
  static const _shownErrors = 10;

  final ImportResultEntity result;
  final Future<void> Function()? onDownloadErrors;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    final textTheme = Theme.of(context).textTheme;
    final wholeFile = batch.failedWholeFile;
    final clean = batch.status == ImportStatus.completed;
    final title = wholeFile
        ? 'No se pudo importar el archivo'
        : '${batch.totalRows ?? 0} filas procesadas';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: wholeFile
            ? AppColors.errorBg
            : clean
            ? AppColors.successBg
            : AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (wholeFile)
            Text(
              batch.errorMessage ?? 'El archivo no se pudo procesar.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            )
          else
            Text(
              '${batch.successfulRows ?? 0} correctas · '
              '${batch.failedRows ?? 0} errores',
            ),
          if (!wholeFile && result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Errores', style: textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final error in result.errors.take(_shownErrors))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Fila ${error.row} (${error.column}): ${error.message}',
                ),
              ),
            if (result.errorsTruncated)
              Text(
                'Se muestran los primeros ${result.errors.length} errores; '
                'descarga el reporte para verlos todos.',
                style: textTheme.bodySmall,
              )
            else if (result.errors.length > _shownErrors)
              Text(
                'Hay más errores. Descarga el reporte completo.',
                style: textTheme.bodySmall,
              ),
          ],
          if (onDownloadErrors != null) ...[
            const SizedBox(height: 12),
            AppAsyncButton(
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

/// "Estudiantes", "Plantilla de clase"... — what an import was for.
String importTypeLabel(ImportType? type) => switch (type) {
  ImportType.students => 'Estudiantes',
  ImportType.teachingPeriod => 'Plantilla de clase',
  ImportType.schoolSetup => 'Configuración del colegio',
  null => 'Importación',
};

/// The history row's second line: what, when, and how it went.
String _historySubtitle(ImportBatchEntity batch) {
  final outcome = switch (batch.status) {
    ImportStatus.queued => 'En cola…',
    ImportStatus.processing => 'Importando…',
    _ when batch.failedWholeFile && batch.errorMessage != null =>
      batch.errorMessage!,
    _ when batch.totalRows != null =>
      '${batch.successfulRows ?? 0}/${batch.totalRows} correctas',
    _ => null,
  };
  return [
    importTypeLabel(batch.type),
    Formatters.dateTime(batch.createdAt),
    ?outcome,
  ].join(' · ');
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
        return Skeleton(
          child: SkeletonRepeat(
            count: 4,
            spacing: 8,
            builder: (context, i) => SkeletonSurface(
              radius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SkeletonTile(
                leading: SkeletonLeading.square,
                titleFactor: SkeletonRepeat.factor(i),
                trailingWidth: 84,
                trailingHeight: 22,
              ),
            ),
          ),
        );
      case ViewStatus.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorState(
            exception: state.error!,
            onRetry: () => context.read<ImportsProvider>().refreshHistory(),
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
                  subtitle: _historySubtitle(batch),
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
    ImportStatus.queued => const AppStatusChip(
      label: 'En cola',
      kind: AppStatusKind.neutral,
    ),
    ImportStatus.processing => const AppStatusChip(
      label: 'Importando',
      kind: AppStatusKind.info,
    ),
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
  };
}

/// Detail content for a single history entry: its counts and dates, and —
/// for a batch with per-row failures — a way to download the full error
/// report. A batch whose whole file was rejected shows why instead.
class ImportBatchDetail extends StatefulWidget {
  const ImportBatchDetail({super.key, required this.batch});

  final ImportBatchEntity batch;

  @override
  State<ImportBatchDetail> createState() => _ImportBatchDetailState();
}

class _ImportBatchDetailState extends State<ImportBatchDetail> {
  bool _downloading = false;

  // Imports from before the backend kept `errorMessage` only recorded why
  // the file was rejected in the audit trail, so for those it's fetched
  // separately.
  bool _loadingReason = false;
  String? _failureReason;

  bool get _needsAuditReason =>
      !widget.batch.hasErrorReport &&
      widget.batch.status == ImportStatus.failed &&
      widget.batch.errorMessage == null;

  @override
  void initState() {
    super.initState();
    if (_needsAuditReason) _loadReason();
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
    final reason = batch.errorMessage ?? _failureReason;

    return AppFormFrame(
      title: batch.fileName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          importStatusChip(batch.status),
          const SizedBox(height: 16),
          _DetailRow(label: 'Tipo', value: importTypeLabel(batch.type)),
          if (batch.totalRows != null) ...[
            _DetailRow(label: 'Filas procesadas', value: '${batch.totalRows}'),
            _DetailRow(
              label: 'Correctas',
              value: '${batch.successfulRows ?? 0}',
            ),
            _DetailRow(label: 'Fallidas', value: '${batch.failedRows ?? 0}'),
          ],
          _DetailRow(
            label: 'Creado',
            value: Formatters.dateTime(batch.createdAt),
          ),
          if (batch.startedAt != null)
            _DetailRow(
              label: 'Iniciado',
              value: Formatters.dateTime(batch.startedAt!),
            ),
          if (batch.completedAt != null)
            _DetailRow(
              label: 'Completado',
              value: Formatters.dateTime(batch.completedAt!),
            ),
          if (batch.isActive) ...[
            const SizedBox(height: 16),
            AppProgressBar(
              label: batch.status == ImportStatus.queued
                  ? 'En cola…'
                  : 'Importando…',
            ),
          ] else if (batch.hasErrorReport) ...[
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
              const Skeleton(
                child: SkeletonSurface(
                  color: AppColors.errorBg,
                  radius: 10,
                  padding: EdgeInsets.all(12),
                  child: SkeletonText(lines: 2),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reason ??
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
