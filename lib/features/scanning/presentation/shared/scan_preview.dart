import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_button.dart';
import 'scanning_controller.dart';

/// The captured image with "Repetir" / "Usar foto".
class ScanPreview extends StatelessWidget {
  const ScanPreview({
    super.key,
    required this.controller,
    required this.uploading,
  });

  final ScanningController controller;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(controller.bytes!, fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Repetir',
                variant: AppButtonVariant.outlined,
                onPressed: uploading ? null : controller.clearImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Usar foto',
                isLoading: uploading,
                onPressed: () => controller.upload(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
