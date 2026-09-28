import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shared/app_button.dart';
import '../../../exams/presentation/providers/submissions_provider.dart';
import '../shared/scan_preview.dart';
import '../shared/scan_result_view.dart';
import '../shared/scanning_controller.dart';

/// Mobile: camera first, gallery as fallback — few taps from capture to
/// result.
class ScanningMobileView extends StatelessWidget {
  const ScanningMobileView({super.key, required this.controller});

  final ScanningController controller;

  Future<void> _capture(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file == null) return;
    controller.setImage(await file.readAsBytes(), file.name);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear hoja')),
      body: switch (provider.uploadState) {
        UploadState.done => ScanResultView(
          submission: provider.lastUploaded!,
          onViewDetail: () => controller.viewResult(context),
          onScanAnother: () => controller.scanAnother(context),
        ),
        _ => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.bytes == null) ...[
              Text('Captura la hoja', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Asegúrate de que la hoja esté bien iluminada y completa en el encuadre.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Abrir cámara',
                icon: Icons.camera_alt_outlined,
                expand: true,
                onPressed: () => _capture(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Elegir de galería',
                variant: AppButtonVariant.outlined,
                icon: Icons.photo_library_outlined,
                expand: true,
                onPressed: () => _capture(ImageSource.gallery),
              ),
            ] else
              ScanPreview(
                controller: controller,
                uploading: provider.uploadState == UploadState.uploading,
              ),
          ],
        ),
      },
    );
  }
}
