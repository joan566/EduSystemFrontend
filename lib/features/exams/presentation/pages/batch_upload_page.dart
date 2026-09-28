import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_upload_zone.dart';
import '../../domain/entities/submission_batch_entity.dart';
import '../providers/submission_batches_provider.dart';
import '../widgets/batch_labels.dart';

/// PDF batch grading entry point: the teacher uploads one PDF with every
/// scanned sheet (booklets included — they are skipped), then follows the
/// batch on [BatchDetailPage]. Also lists earlier batches so one still
/// running can be picked up again.
class BatchUploadPage extends StatefulWidget {
  const BatchUploadPage({super.key, required this.examId});

  final int examId;

  @override
  State<BatchUploadPage> createState() => _BatchUploadPageState();
}

class _BatchUploadPageState extends State<BatchUploadPage> {
  PickedFile? _file;
  bool _replace = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  void _loadHistory() =>
      context.read<SubmissionBatchesProvider>().loadHistory(widget.examId);

  void _onFilePicked(PickedFile file) {
    final size = file.size ?? file.bytes.length;
    if (size > AppConfig.maxUploadSizeBytes) {
      context.showError(
        BatchLabels.uploadError(
          const AppException(code: AppErrorCode.fileTooLarge, message: ''),
        )!,
      );
      return;
    }
    setState(() => _file = file);
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    final provider = context.read<SubmissionBatchesProvider>();
    try {
      final batch = await provider.upload(
        widget.examId,
        pdfBytes: file.bytes,
        fileName: file.name,
        replace: _replace,
      );
      if (!mounted) return;
      setState(() => _file = null);
      _openBatch(batch.id);
    } on AppException catch (e) {
      if (!mounted) return;
      final message = BatchLabels.uploadError(e);
      if (message != null) {
        context.showError(message);
      } else {
        context.showApiError(e);
      }
    }
  }

  Future<void> _openBatch(int batchId) async {
    await context.push(RoutePaths.submissionBatch(widget.examId, batchId));
    if (mounted) _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionBatchesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar PDF escaneado')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const AppPageHeader(
                title: 'Sube todas las hojas en un PDF',
                subtitle:
                    'Máximo 60 MB y 200 páginas. Los cuadernillos y páginas en blanco se omiten solos. '
                    'La calificación sigue aunque cierres esta pantalla.',
              ),
              if (_file == null)
                AppUploadZone(
                  allowedExtensions: const ['pdf'],
                  title: 'Arrastra el PDF escaneado aquí',
                  subtitle: 'Solo archivos .pdf sin contraseña, máximo 60 MB.',
                  onFilePicked: _onFilePicked,
                )
              else
                AppSelectedFileTile(
                  file: _file!,
                  onRemove: provider.uploading
                      ? () {}
                      : () => setState(() => _file = null),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _replace,
                onChanged: provider.uploading
                    ? null
                    : (value) => setState(() => _replace = value),
                title: const Text('Reemplazar resultados existentes'),
                subtitle: const Text(
                  'Recalifica a los estudiantes que ya tenían nota. Si está apagado, sus hojas se rechazan.',
                ),
              ),
              const SizedBox(height: 12),
              if (provider.uploading) ...[
                LinearProgressIndicator(value: provider.uploadProgress),
                const SizedBox(height: 12),
              ],
              AppButton(
                label: 'Subir y calificar',
                icon: Icons.upload_file_outlined,
                expand: true,
                isLoading: provider.uploading,
                onPressed: _file == null ? null : _upload,
              ),
              const SizedBox(height: 32),
              Text('Lotes anteriores', style: context.textStyles.titleMedium),
              const SizedBox(height: 12),
              _History(state: provider.history, onOpen: _openBatch, onRetry: _loadHistory),
            ],
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.state,
    required this.onOpen,
    required this.onRetry,
  });

  final ListViewState<SubmissionBatchSummaryEntity> state;
  final void Function(int batchId) onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: AppLoading(),
        );
      case ViewStatus.error:
        return AppErrorState(exception: state.error!, onRetry: onRetry);
      case ViewStatus.empty:
        return Text(
          'Todavía no has subido ningún PDF para este examen.',
          style: context.textStyles.bodySmall,
        );
      case ViewStatus.success:
        return Column(
          children: [
            for (final batch in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppListTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: batch.fileName,
                  subtitle: _subtitle(batch),
                  trailing: BatchLabels.batchStatusChip(batch.status),
                  onTap: () => onOpen(batch.id),
                ),
              ),
          ],
        );
    }
  }

  String _subtitle(SubmissionBatchSummaryEntity batch) {
    final date = batch.createdAt == null
        ? ''
        : '${Formatters.dateTime(batch.createdAt!)} · ';
    final progress = batch.isFinished
        ? '${batch.totalPages} páginas'
        : '${batch.processedPages} de ${batch.totalPages} páginas';
    return '$date$progress';
  }
}
