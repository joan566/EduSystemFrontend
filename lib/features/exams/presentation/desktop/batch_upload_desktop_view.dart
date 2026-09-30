import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_upload_zone.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../providers/submission_batches_provider.dart';
import '../shared/batch_upload_controller.dart';
import '../shared/batch_upload_widgets.dart';

/// Desktop: drop zone + options on the left, earlier batches on the right.
class BatchUploadDesktopView extends StatelessWidget {
  const BatchUploadDesktopView({super.key, required this.controller});

  final BatchUploadController controller;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionBatchesProvider>();

    return Scaffold(
      body: ListView(
        children: [
          DesktopPageHeader(
            title: 'Calificar PDF escaneado',
            subtitle:
                'Máximo 60 MB y 200 páginas. Los cuadernillos y páginas en blanco se omiten solos. '
                'La calificación sigue aunque cierres esta pantalla.',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppCard(
                    child: BatchUploadForm(
                      controller: controller,
                      intake: DesktopUploadZone(
                        allowedExtensions: const ['pdf'],
                        title: 'Arrastra el PDF escaneado aquí',
                        subtitle:
                            'Solo archivos .pdf sin contraseña, máximo 60 MB.',
                        onFilePicked: (file) =>
                            controller.pickFile(context, file),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Lotes anteriores',
                        style: context.textStyles.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      BatchHistoryList(
                        state: provider.history(controller.examId),
                        onOpen: (id) => controller.openBatch(context, id),
                        onRetry: () => controller.refreshHistory(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
