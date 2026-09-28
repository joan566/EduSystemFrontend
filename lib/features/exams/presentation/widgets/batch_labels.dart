import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/submission_batch_entity.dart';

/// Spanish copy for PDF batch grading. The backend's `message` and
/// `statusDetail` are English, so the UI maps stable codes instead.
class BatchLabels {
  BatchLabels._();

  /// Immediate errors from `POST .../submissions/batches`. Null means the
  /// generic [AppContext.showApiError] mapping applies.
  static String? uploadError(AppException e) => switch (e.code) {
    'INVALID_PDF' =>
      'El archivo no es un PDF válido. Vuelve a exportar el escaneo.',
    'TOO_MANY_PAGES' =>
      'Divide el escaneo en archivos de hasta 200 páginas.',
    AppErrorCode.fileTooLarge =>
      'El archivo pesa más de 60 MB. Escanea en escala de grises o a 200–300 ppp.',
    AppErrorCode.resourceNotFound => 'No se encontró el examen.',
    'EXAM_NOT_READY' => 'Completa las preguntas del examen antes de calificar.',
    'GRADING_CONFIGURATION_REQUIRED' =>
      'Configura la escala de notas del periodo.',
    _ => null,
  };

  /// Why a `REJECTED` page stored nothing.
  static String pageError(String? code) => switch (code) {
    'QR_NOT_DETECTED' =>
      'No se pudo leer el código QR. Sube esta hoja como foto e indica el estudiante.',
    'INVALID_QR' => 'El código QR no corresponde a una hoja de EduSistem.',
    'QR_EXAM_MISMATCH' => 'Esta hoja pertenece a otro examen.',
    'QR_STUDENT_NOT_FOUND' => 'El estudiante de esta hoja no está registrado.',
    'STUDENT_NOT_IN_GROUP' => 'El estudiante no pertenece a este grupo.',
    'SUBMISSION_ALREADY_EXISTS' =>
      'Este estudiante ya estaba calificado. Súbelo con “Reemplazar” para recalificar.',
    'DUPLICATE_IN_BATCH' =>
      'Hoja repetida en este PDF: cuenta la primera página del estudiante.',
    'PAGE_UNREADABLE' => 'No se pudo leer esta página del PDF.',
    'EXAM_NOT_READY' => 'Completa las preguntas del examen antes de calificar.',
    'GRADING_CONFIGURATION_REQUIRED' =>
      'Configura la escala de notas del periodo.',
    _ => 'Ocurrió un error al procesar esta página. Inténtalo de nuevo.',
  };

  /// Whether re-uploading that sheet as a single photo can fix the page.
  static bool canRetryAsPhoto(BatchPage page) =>
      page.outcome == BatchPageOutcome.failed ||
      (page.outcome == BatchPageOutcome.rejected &&
          const {
            'QR_NOT_DETECTED',
            'PAGE_UNREADABLE',
            'PROCESSING_ERROR',
          }.contains(page.errorCode));

  static AppStatusChip batchStatusChip(SubmissionBatchStatus status) =>
      switch (status) {
        SubmissionBatchStatus.queued => const AppStatusChip(
          label: 'En cola',
          kind: AppStatusKind.neutral,
        ),
        SubmissionBatchStatus.processing => const AppStatusChip(
          label: 'Procesando',
          kind: AppStatusKind.info,
        ),
        SubmissionBatchStatus.completed => const AppStatusChip(
          label: 'Completado',
          kind: AppStatusKind.success,
        ),
        SubmissionBatchStatus.failed => const AppStatusChip(
          label: 'Falló',
          kind: AppStatusKind.error,
        ),
      };

  static AppStatusChip outcomeChip(BatchPageOutcome outcome) =>
      switch (outcome) {
        BatchPageOutcome.processed => const AppStatusChip(
          label: 'Procesada',
          kind: AppStatusKind.success,
        ),
        BatchPageOutcome.reviewRequired => const AppStatusChip(
          label: 'Requiere revisión',
          kind: AppStatusKind.warning,
        ),
        BatchPageOutcome.failed => const AppStatusChip(
          label: 'Falló',
          kind: AppStatusKind.error,
        ),
        BatchPageOutcome.rejected => const AppStatusChip(
          label: 'Rechazada',
          kind: AppStatusKind.error,
        ),
        BatchPageOutcome.skipped => const AppStatusChip(
          label: 'Omitida',
          kind: AppStatusKind.neutral,
        ),
      };

  static IconData outcomeIcon(BatchPageOutcome outcome) => switch (outcome) {
    BatchPageOutcome.processed => Icons.check_circle_outline,
    BatchPageOutcome.reviewRequired => Icons.warning_amber_rounded,
    BatchPageOutcome.failed => Icons.error_outline,
    BatchPageOutcome.rejected => Icons.block_outlined,
    BatchPageOutcome.skipped => Icons.description_outlined,
  };
}
