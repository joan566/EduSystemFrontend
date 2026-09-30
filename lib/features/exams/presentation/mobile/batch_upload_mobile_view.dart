import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/mobile/mobile_file_picker_button.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_upload_controller.dart';
import '../shared/batch_upload_widgets.dart';

class BatchUploadMobileView extends StatelessWidget {
  const BatchUploadMobileView({super.key, required this.controller});

  final BatchUploadController controller;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionBatchesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sube todas las hojas en un PDF',
            style: context.textStyles.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Máximo 60 MB y 200 páginas. Los cuadernillos y páginas en blanco '
            'se omiten solos. La calificación sigue aunque cierres esta '
            'pantalla.',
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          BatchUploadForm(
            controller: controller,
            intake: MobileFilePickerButton(
              allowedExtensions: const ['pdf'],
              label: 'Seleccionar PDF',
              hint: 'Solo archivos .pdf sin contraseña, máximo 60 MB.',
              onFilePicked: (file) => controller.pickFile(context, file),
            ),
          ),
          const SizedBox(height: 28),
          Text('Lotes anteriores', style: context.textStyles.titleMedium),
          const SizedBox(height: 12),
          BatchHistoryList(
            state: provider.history(controller.examId),
            onOpen: (id) => controller.openBatch(context, id),
            onRetry: () => controller.refreshHistory(context),
          ),
        ],
      ),
    );
  }
}
