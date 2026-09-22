import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/downloads.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_upload_zone.dart';
import '../../../exports/data/export_datasource.dart';
import '../../../imports/domain/entities/import_batch_entity.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../teaching/presentation/widgets/teaching_period_selector.dart';

/// Single screen for every Excel import/export flow (§ backend unified
/// these behind one set of endpoints, so the UI mirrors that: one place,
/// not a separate "imports" page and "exports" page). The teaching-period
/// selector at the top drives every period-scoped card below it.
class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  TeachingPeriodEntity? _period;

  PickedFile? _studentsPicked;
  PickedFile? _periodPicked;
  PickedFile? _schoolSetupPicked;

  String? _exportLoadingAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ImportsProvider>().loadHistory(),
    );
  }

  Future<void> _runExport(String action, Future<void> Function() task) async {
    setState(() => _exportLoadingAction = action);
    try {
      await task();
      if (mounted) context.showSuccess('Archivo descargado.');
    } catch (_) {
      if (mounted) context.showError('No se pudo generar la exportación.');
    } finally {
      if (mounted) setState(() => _exportLoadingAction = null);
    }
  }

  Future<void> _downloadStudentsTemplate() async {
    try {
      await context.read<ImportsProvider>().downloadTemplate();
      if (mounted) context.showSuccess('Plantilla descargada.');
    } catch (_) {
      if (mounted) context.showError('No se pudo descargar la plantilla.');
    }
  }

  Future<void> _uploadStudents() async {
    if (_studentsPicked == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.upload(
      fileName: _studentsPicked!.name,
      bytes: _studentsPicked!.bytes,
    );
    if (!mounted) return;
    if (provider.uploadStatus == UploadStatus.error &&
        provider.uploadError != null) {
      context.showApiError(provider.uploadError!);
    }
  }

  Future<void> _downloadPeriodFull() async {
    if (_period == null) return;
    await _runExport('full', () async {
      final download = await context
          .read<ExportDataSource>()
          .exportTeachingPeriodFull(teachingPeriodId: _period!.id);
      await Downloads.save(download);
    });
  }

  Future<void> _uploadPeriod() async {
    if (_periodPicked == null || _period == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.uploadTeachingPeriod(
      teachingPeriodId: _period!.id,
      fileName: _periodPicked!.name,
      bytes: _periodPicked!.bytes,
    );
    if (!mounted) return;
    if (provider.periodUploadStatus == UploadStatus.error &&
        provider.periodUploadError != null) {
      context.showApiError(provider.periodUploadError!);
    }
  }

  Future<void> _downloadSchoolSetupTemplate() async {
    try {
      await context.read<ImportsProvider>().downloadSchoolSetupTemplate();
      if (mounted) context.showSuccess('Plantilla descargada.');
    } catch (_) {
      if (mounted) context.showError('No se pudo descargar la plantilla.');
    }
  }

  Future<void> _uploadSchoolSetup() async {
    if (_schoolSetupPicked == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.uploadSchoolSetup(
      fileName: _schoolSetupPicked!.name,
      bytes: _schoolSetupPicked!.bytes,
    );
    if (!mounted) return;
    if (provider.schoolSetupUploadStatus == UploadStatus.error &&
        provider.schoolSetupUploadError != null) {
      context.showApiError(provider.schoolSetupUploadError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImportsProvider>();
    final dataSource = context.read<ExportDataSource>();
    final hasPeriods = context.watch<TeachingProvider>().allPeriods.isNotEmpty;

    return Scaffold(
      body: ListView(
        children: [
          const AppPageHeader(
            title: 'Importar y exportar',
            subtitle:
                'Sube o descarga estudiantes, calificaciones y asistencia en Excel.',
          ),

          // --- Configuración del colegio: no depende de ninguna clase ---
          // (de hecho puede crear las clases). Va primero y separado de
          // todo lo que sí requiere elegir una clase abajo.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configuración completa del colegio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un Excel con 9 hojas para cargar todo de una vez: '
                    'periodos, grados, materias, cursos, clases, estudiantes, '
                    'actividades, notas y asistencia. No necesitas elegir una '
                    'clase para esto — todas las hojas son opcionales, así '
                    'que puedes omitir lo que ya tengas cargado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Descargar plantilla',
                    icon: Icons.download_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: _downloadSchoolSetupTemplate,
                  ),
                  const SizedBox(height: 20),
                  if (_schoolSetupPicked == null)
                    AppUploadZone(
                      allowedExtensions: const ['xlsx'],
                      title: 'Arrastra tu archivo aquí',
                      subtitle: 'Solo archivos .xlsx, máximo 15 MB',
                      onFilePicked: (file) =>
                          setState(() => _schoolSetupPicked = file),
                    )
                  else ...[
                    AppSelectedFileTile(
                      file: _schoolSetupPicked!,
                      onRemove: () => setState(() => _schoolSetupPicked = null),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Importar',
                      isLoading:
                          provider.schoolSetupUploadStatus ==
                          UploadStatus.uploading,
                      onPressed: _uploadSchoolSetup,
                    ),
                  ],
                  if (provider.schoolSetupUploadStatus == UploadStatus.done &&
                      provider.schoolSetupLastResult != null) ...[
                    const SizedBox(height: 20),
                    _ImportResultSummary(
                      result: provider.schoolSetupLastResult!,
                      onDownloadErrors:
                          provider.schoolSetupLastResult!.batch.hasErrorReport
                          ? () => context
                                .read<ImportsProvider>()
                                .downloadErrorReport(
                                  provider.schoolSetupLastResult!.batch.id,
                                )
                          : null,
                      onDismiss: () {
                        context
                            .read<ImportsProvider>()
                            .resetSchoolSetupUpload();
                        setState(() => _schoolSetupPicked = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Datos de una clase específica',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TeachingPeriodSelector(
              value: _period,
              onChanged: (period) => setState(() => _period = period),
              label:
                  'Clase (opcional para estudiantes, requerida para el resto)',
            ),
          ),
          const SizedBox(height: 16),

          // --- Las dos plantillas, una al lado de la otra ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Plantillas de esta clase',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elige cuál necesitas descargar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TemplateOption(
                          title: 'Solo estudiantes',
                          description:
                              'Una hoja para matricular estudiantes nuevos en '
                              'varias clases a la vez. No incluye notas ni '
                              'asistencia.',
                          buttonLabel: 'Plantilla de estudiantes',
                          onPressed: _downloadStudentsTemplate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TemplateOption(
                          title: 'De esta clase',
                          badge: const _RecommendedChip(),
                          description:
                              'Un Excel con 3 hojas: Estudiantes, '
                              'Calificaciones y Asistencia de la clase '
                              'seleccionada arriba. Sirve aunque todavía no '
                              'tenga estudiantes matriculados.',
                          buttonLabel: 'Plantilla de la clase',
                          isLoading: _exportLoadingAction == 'full',
                          onPressed: _period == null
                              ? null
                              : _downloadPeriodFull,
                          disabledHint: hasPeriods
                              ? 'Selecciona una clase arriba primero.'
                              : 'Aún no tienes clases asignadas.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Periodo completo: el flujo recomendado -------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Subir plantilla de la clase',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const _RecommendedChip(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Descarga la plantilla "De esta clase" arriba, edítala '
                    'en Excel y sube aquí el mismo archivo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_periodPicked == null)
                    AppUploadZone(
                      allowedExtensions: const ['xlsx'],
                      title: 'Arrastra tu archivo aquí',
                      subtitle: 'Solo archivos .xlsx, máximo 15 MB',
                      onFilePicked: (file) =>
                          setState(() => _periodPicked = file),
                    )
                  else ...[
                    AppSelectedFileTile(
                      file: _periodPicked!,
                      onRemove: () => setState(() => _periodPicked = null),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Importar',
                      isLoading:
                          provider.periodUploadStatus == UploadStatus.uploading,
                      onPressed: _period == null ? null : _uploadPeriod,
                    ),
                  ],
                  if (provider.periodUploadStatus == UploadStatus.done &&
                      provider.periodLastResult != null) ...[
                    const SizedBox(height: 20),
                    _ImportResultSummary(
                      result: provider.periodLastResult!,
                      onDownloadErrors:
                          provider.periodLastResult!.batch.hasErrorReport
                          ? () => context
                                .read<ImportsProvider>()
                                .downloadErrorReport(
                                  provider.periodLastResult!.batch.id,
                                )
                          : null,
                      onDismiss: () {
                        context.read<ImportsProvider>().resetPeriodUpload();
                        setState(() => _periodPicked = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Estudiantes: alta y listado, sin notas ni asistencia -----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subir matrícula multi-clase',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Descarga la plantilla de estudiantes arriba, complétala '
                    '(una fila por estudiante, con su curso en la columna '
                    'group) y súbela aquí. No toca calificaciones ni '
                    'asistencia.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Exportar listado actual',
                    icon: Icons.download_outlined,
                    variant: AppButtonVariant.outlined,
                    isLoading: _exportLoadingAction == 'students',
                    onPressed: () => _runExport('students', () async {
                      final download = await dataSource.exportStudents(
                        teachingPeriodId: _period?.id,
                      );
                      await Downloads.save(download);
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_studentsPicked == null)
                    AppUploadZone(
                      allowedExtensions: const ['xlsx'],
                      title: 'Arrastra tu archivo aquí',
                      subtitle: 'Solo archivos .xlsx, máximo 15 MB',
                      onFilePicked: (file) =>
                          setState(() => _studentsPicked = file),
                    )
                  else ...[
                    AppSelectedFileTile(
                      file: _studentsPicked!,
                      onRemove: () => setState(() => _studentsPicked = null),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Importar',
                      isLoading:
                          provider.uploadStatus == UploadStatus.uploading,
                      onPressed: _uploadStudents,
                    ),
                  ],
                  if (provider.uploadStatus == UploadStatus.done &&
                      provider.lastResult != null) ...[
                    const SizedBox(height: 20),
                    _ImportResultSummary(
                      result: provider.lastResult!,
                      onDownloadErrors:
                          provider.lastResult!.batch.hasErrorReport
                          ? () => context
                                .read<ImportsProvider>()
                                .downloadErrorReport(
                                  provider.lastResult!.batch.id,
                                )
                          : null,
                      onDismiss: () {
                        context.read<ImportsProvider>().resetUpload();
                        setState(() => _studentsPicked = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Exportaciones sueltas: solo notas o solo asistencia ------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Exportar por separado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para cuando solo necesitas un archivo de calificaciones o '
                    'de asistencia, sin el resto del periodo completo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  AppListTile(
                    icon: Icons.grade_outlined,
                    title: 'Calificaciones',
                    subtitle: 'Notas del periodo seleccionado, por estudiante.',
                    subtitleMaxLines: 2,
                    trailing: AppButton(
                      label: 'Exportar',
                      variant: AppButtonVariant.outlined,
                      isLoading: _exportLoadingAction == 'grades',
                      onPressed: _period == null
                          ? null
                          : () => _runExport('grades', () async {
                              final download = await dataSource.exportGrades(
                                teachingPeriodId: _period!.id,
                              );
                              await Downloads.save(download);
                            }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppListTile(
                    icon: Icons.checklist_outlined,
                    title: 'Asistencia',
                    subtitle:
                        'Historial de asistencia del periodo seleccionado.',
                    subtitleMaxLines: 2,
                    trailing: AppButton(
                      label: 'Exportar',
                      variant: AppButtonVariant.outlined,
                      isLoading: _exportLoadingAction == 'attendance',
                      onPressed: _period == null
                          ? null
                          : () => _runExport('attendance', () async {
                              final download = await dataSource
                                  .exportAttendance(
                                    teachingPeriodId: _period!.id,
                                  );
                              await Downloads.save(download);
                            }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Historial de importaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          _HistoryList(state: provider.historyState),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
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

  const _TemplateOption({
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
              if (badge != null) badge!,
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

class _RecommendedChip extends StatelessWidget {
  const _RecommendedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Recomendado',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _ImportResultSummary extends StatelessWidget {
  const _ImportResultSummary({
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

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state});

  final ListViewState<ImportBatchEntity> state;

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
          child: Text('Aún no has realizado importaciones.'),
        );
      case ViewStatus.success:
        return Column(
          children: [
            for (final batch in state.items)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AppListTile(
                  icon: Icons.description_outlined,
                  title: batch.fileName,
                  subtitle:
                      '${Formatters.dateTime(batch.createdAt)} · '
                      '${batch.successfulRows}/${batch.totalRows} correctas',
                  trailing: _importStatusChip(batch.status),
                  onTap: () => showAppDialog(
                    context,
                    child: _ImportBatchDetailDialog(batch: batch),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

Widget _importStatusChip(ImportStatus status) {
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

/// Detail view for a single history entry: the counts already shown in the
/// list, plus — for a batch with per-row failures — a way to download the
/// full error report. A batch that failed before any row was even
/// evaluated (bad file type, missing columns) has no report to offer, so it
/// gets an explanatory note instead of a dead-end status chip.
class _ImportBatchDetailDialog extends StatefulWidget {
  const _ImportBatchDetailDialog({required this.batch});

  final ImportBatchEntity batch;

  @override
  State<_ImportBatchDetailDialog> createState() =>
      _ImportBatchDetailDialogState();
}

class _ImportBatchDetailDialogState extends State<_ImportBatchDetailDialog> {
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
    try {
      await context.read<ImportsProvider>().downloadErrorReport(
        widget.batch.id,
      );
      if (mounted) context.showSuccess('Reporte descargado.');
    } catch (_) {
      if (mounted) context.showError('No se pudo descargar el reporte.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final textTheme = Theme.of(context).textTheme;

    return AppDialogFrame(
      title: batch.fileName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _importStatusChip(batch.status),
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
