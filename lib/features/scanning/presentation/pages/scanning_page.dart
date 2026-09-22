import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_upload_zone.dart';
import '../../../exams/domain/entities/submission_entity.dart';
import '../../../exams/presentation/providers/submissions_provider.dart';

/// Answer-sheet capture flow (§42-45): camera-first on mobile (few taps:
/// capture -> preview -> confirm -> upload -> result), drag & drop /
/// file picker on desktop. The image never leaves the client for local
/// processing — it's uploaded as-is and the backend does the OMR (§45).
class ScanningPage extends StatefulWidget {
  const ScanningPage({super.key, required this.examId});

  final int examId;

  @override
  State<ScanningPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  Uint8List? _bytes;
  String _fileName = 'hoja.jpg';

  Future<void> _capture(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 2400);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bytes = bytes;
      _fileName = file.name;
    });
  }

  void _onFilePicked(PickedFile file) {
    setState(() {
      _bytes = file.bytes;
      _fileName = file.name;
    });
  }

  Future<void> _upload({bool replace = false}) async {
    if (_bytes == null) return;
    final provider = context.read<SubmissionsProvider>();
    await provider.upload(
      widget.examId,
      imageBytes: _bytes!,
      fileName: _fileName,
      replace: replace,
    );
    if (!mounted) return;

    if (provider.uploadState == UploadState.error) {
      final error = provider.uploadError!;
      if (error.code == 'SUBMISSION_ALREADY_EXISTS') {
        final confirmed = await showAppConfirmDialog(
          context,
          title: 'Este estudiante ya tiene una hoja procesada',
          message: '¿Quieres reemplazar el resultado anterior con esta nueva foto?',
          confirmLabel: 'Reemplazar',
          isDestructive: false,
        );
        if (confirmed && mounted) await _upload(replace: true);
        return;
      }
      context.showApiError(error);
    }
  }

  void _reset() {
    context.read<SubmissionsProvider>().resetUpload();
    setState(() => _bytes = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubmissionsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear hoja de respuesta')),
      body: switch (provider.uploadState) {
        UploadState.done => _ResultView(
            submission: provider.lastUploaded!,
            onViewDetail: () => context.pushReplacement(
              RoutePaths.submissionDetail(widget.examId, provider.lastUploaded!.id),
            ),
            onScanAnother: _reset,
          ),
        _ => _CaptureView(
            bytes: _bytes,
            uploading: provider.uploadState == UploadState.uploading,
            onCapture: _capture,
            onFilePicked: _onFilePicked,
            onClear: () => setState(() => _bytes = null),
            onUpload: () => _upload(),
          ),
      },
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.bytes,
    required this.uploading,
    required this.onCapture,
    required this.onFilePicked,
    required this.onClear,
    required this.onUpload,
  });

  final Uint8List? bytes;
  final bool uploading;
  final void Function(ImageSource) onCapture;
  final void Function(PickedFile) onFilePicked;
  final VoidCallback onClear;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (bytes == null) ...[
          const AppPageHeader(
            title: 'Captura la hoja',
            subtitle: 'Asegúrate de que la hoja esté bien iluminada y completa en el encuadre.',
          ),
          if (context.isMobile)
            Column(
              children: [
                AppButton(
                  label: 'Abrir cámara',
                  icon: Icons.camera_alt_outlined,
                  expand: true,
                  onPressed: () => onCapture(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Elegir de galería',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.photo_library_outlined,
                  expand: true,
                  onPressed: () => onCapture(ImageSource.gallery),
                ),
              ],
            )
          else
            AppUploadZone(
              allowedExtensions: const ['jpg', 'jpeg', 'png'],
              title: 'Arrastra una hoja de respuesta aquí',
              subtitle: 'Formatos aceptados: JPG, PNG. Máximo 15 MB.',
              onFilePicked: onFilePicked,
            ),
        ] else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes!, fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Repetir',
                  variant: AppButtonVariant.outlined,
                  onPressed: uploading ? null : onClear,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(label: 'Usar foto', isLoading: uploading, onPressed: onUpload),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.submission,
    required this.onViewDetail,
    required this.onScanAnother,
  });

  final SubmissionEntity submission;
  final VoidCallback onViewDetail;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    final needsReview = submission.status == SubmissionStatus.reviewRequired;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsReview ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 56,
              color: needsReview ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              submission.student.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              needsReview ? 'Algunas respuestas necesitan revisión' : 'Hoja procesada correctamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (submission.finalGrade != null && submission.scaleMaximum != null)
              Text(
                Formatters.grade(submission.finalGrade!, submission.scaleMaximum!),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            const SizedBox(height: 28),
            AppButton(label: 'Ver detalle', expand: true, onPressed: onViewDetail),
            const SizedBox(height: 12),
            AppButton(
              label: 'Escanear otra hoja',
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: onScanAnother,
            ),
          ],
        ),
      ),
    );
  }
}
