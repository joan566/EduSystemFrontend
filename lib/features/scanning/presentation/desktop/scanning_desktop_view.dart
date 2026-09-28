import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_upload_zone.dart';
import '../../../exams/presentation/providers/submissions_provider.dart';
import '../shared/scan_preview.dart';
import '../shared/scan_result_view.dart';
import '../shared/scanning_controller.dart';

/// Desktop: drag & drop (or pick) a photo/scan of the sheet.
class ScanningDesktopView extends StatelessWidget {
  const ScanningDesktopView({super.key, required this.controller});

  final ScanningController controller;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionsProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            title: 'Escanear hoja de respuesta',
            subtitle:
                'Asegúrate de que la hoja esté bien iluminada y completa en el encuadre.',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: switch (provider.uploadState) {
              UploadState.done => ScanResultView(
                submission: provider.lastUploaded!,
                onViewDetail: () => controller.viewResult(context),
                onScanAnother: () => controller.scanAnother(context),
              ),
              _ => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      if (controller.bytes == null)
                        DesktopUploadZone(
                          allowedExtensions: const ['jpg', 'jpeg', 'png'],
                          title: 'Arrastra una hoja de respuesta aquí',
                          subtitle:
                              'Formatos aceptados: JPG, PNG. Máximo 60 MB.',
                          onFilePicked: (file) =>
                              controller.setImage(file.bytes, file.name),
                        )
                      else
                        ScanPreview(
                          controller: controller,
                          uploading:
                              provider.uploadState == UploadState.uploading,
                        ),
                    ],
                  ),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}
