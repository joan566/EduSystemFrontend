import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../domain/entities/submission_batch_entity.dart';
import '../providers/submission_batches_provider.dart';
import 'batch_labels.dart';
import 'batch_upload_controller.dart';

/// Picked file (or the platform's [intake]) + "replace" switch + upload
/// button with progress.
class BatchUploadForm extends StatelessWidget {
  const BatchUploadForm({
    super.key,
    required this.controller,
    required this.intake,
  });

  final BatchUploadController controller;
  final Widget intake;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionBatchesProvider>();
    final file = controller.file;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (file == null)
          intake
        else
          AppSelectedFileTile(
            file: file,
            onRemove: provider.uploading ? () {} : controller.clearFile,
          ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.replace,
          onChanged: provider.uploading ? null : controller.setReplace,
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
          onPressed: file == null ? null : () => controller.upload(context),
        ),
      ],
    );
  }
}

class BatchHistoryList extends StatelessWidget {
  const BatchHistoryList({
    super.key,
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
