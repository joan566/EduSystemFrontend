import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../exams/domain/entities/submission_entity.dart';

/// Outcome of an uploaded sheet: student, status, grade, next actions.
class ScanResultView extends StatelessWidget {
  const ScanResultView({
    super.key,
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
              needsReview
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
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
              needsReview
                  ? 'Algunas respuestas necesitan revisión'
                  : 'Hoja procesada correctamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (submission.finalGrade != null &&
                submission.scaleMaximum != null)
              Text(
                Formatters.grade(
                  submission.finalGrade!,
                  submission.scaleMaximum!,
                ),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Ver detalle',
              expand: true,
              onPressed: onViewDetail,
            ),
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
