import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../imports/domain/entities/import_batch_entity.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import 'data_management_controller.dart';
import 'data_management_widgets.dart';

/// Builds the platform's file-intake control (drop zone on desktop, picker
/// button on mobile). Each view passes its own; the sections below are
/// content only.
typedef FileIntakeBuilder =
    Widget Function(ValueChanged<PickedFile> onFilePicked);

/// "Configuración completa del colegio": doesn't depend on any class (it
/// can even create them), so it's shown first and apart from the rest.
class SchoolSetupCard extends StatelessWidget {
  const SchoolSetupCard({
    super.key,
    required this.controller,
    required this.intake,
  });

  final DataManagementController controller;
  final FileIntakeBuilder intake;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImportsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configuración completa del colegio',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Un Excel con 9 hojas para cargar todo de una vez: '
            'periodos, grados, materias, cursos, clases, estudiantes, '
            'actividades, notas y asistencia. No necesitas elegir una '
            'clase para esto — todas las hojas son opcionales, así '
            'que puedes omitir lo que ya tengas cargado.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Descargar plantilla',
            icon: Icons.download_outlined,
            variant: AppButtonVariant.outlined,
            onPressed: () => controller.downloadSchoolSetupTemplate(context),
          ),
          const SizedBox(height: 20),
          _UploadBlock(
            picked: controller.schoolSetupPicked,
            intake: intake,
            onPicked: controller.pickSchoolSetup,
            uploading:
                provider.schoolSetupUploadStatus == UploadStatus.uploading,
            onUpload: () => controller.uploadSchoolSetup(context),
            done: provider.schoolSetupUploadStatus == UploadStatus.done,
            result: provider.schoolSetupLastResult,
            onDismissResult: () => controller.dismissSchoolSetupResult(context),
          ),
        ],
      ),
    );
  }
}

/// The two downloadable templates for class data. Returned as separate
/// widgets so each view arranges them its own way.
List<Widget> classTemplateOptions(
  BuildContext context,
  DataManagementController controller,
) {
  final hasPeriods = context.watch<TeachingProvider>().allPeriods.isNotEmpty;
  return [
    DataTemplateOption(
      title: 'Solo estudiantes',
      description:
          'Una hoja para matricular estudiantes nuevos en '
          'varias clases a la vez. No incluye notas ni '
          'asistencia.',
      buttonLabel: 'Plantilla de estudiantes',
      onPressed: () => controller.downloadStudentsTemplate(context),
    ),
    DataTemplateOption(
      title: 'De esta clase',
      badge: const RecommendedChip(),
      description:
          'Un Excel con 3 hojas: Estudiantes, '
          'Calificaciones y Asistencia de la clase '
          'seleccionada arriba. Sirve aunque todavía no '
          'tenga estudiantes matriculados.',
      buttonLabel: 'Plantilla de la clase',
      isLoading: controller.isExporting('full'),
      onPressed: controller.period == null
          ? null
          : () => controller.downloadPeriodFull(context),
      disabledHint: hasPeriods
          ? 'Selecciona una clase arriba primero.'
          : 'Aún no tienes clases asignadas.',
    ),
  ];
}

/// Upload of the "De esta clase" template — the recommended flow.
class PeriodUploadCard extends StatelessWidget {
  const PeriodUploadCard({
    super.key,
    required this.controller,
    required this.intake,
  });

  final DataManagementController controller;
  final FileIntakeBuilder intake;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImportsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subir plantilla de la clase',
                  style: textTheme.titleMedium,
                ),
              ),
              const RecommendedChip(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Descarga la plantilla "De esta clase" arriba, edítala '
            'en Excel y sube aquí el mismo archivo.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _UploadBlock(
            picked: controller.periodPicked,
            intake: intake,
            onPicked: controller.pickPeriod,
            uploading: provider.periodUploadStatus == UploadStatus.uploading,
            onUpload: controller.period == null
                ? null
                : () => controller.uploadPeriod(context),
            done: provider.periodUploadStatus == UploadStatus.done,
            result: provider.periodLastResult,
            onDismissResult: () => controller.dismissPeriodResult(context),
          ),
        ],
      ),
    );
  }
}

/// Multi-class enrollment upload: students only, no grades or attendance.
class StudentsUploadCard extends StatelessWidget {
  const StudentsUploadCard({
    super.key,
    required this.controller,
    required this.intake,
  });

  final DataManagementController controller;
  final FileIntakeBuilder intake;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImportsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Subir matrícula multi-clase', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Descarga la plantilla de estudiantes arriba, complétala '
            '(una fila por estudiante, con su curso en la columna '
            'group) y súbela aquí. No toca calificaciones ni '
            'asistencia.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Exportar listado actual',
            icon: Icons.download_outlined,
            variant: AppButtonVariant.outlined,
            isLoading: controller.isExporting('students'),
            onPressed: () => controller.exportStudents(context),
          ),
          const SizedBox(height: 16),
          _UploadBlock(
            picked: controller.studentsPicked,
            intake: intake,
            onPicked: controller.pickStudents,
            uploading: provider.uploadStatus == UploadStatus.uploading,
            onUpload: () => controller.uploadStudents(context),
            done: provider.uploadStatus == UploadStatus.done,
            result: provider.lastResult,
            onDismissResult: () => controller.dismissStudentsResult(context),
          ),
        ],
      ),
    );
  }
}

/// Grades-only and attendance-only exports.
class SeparateExportsCard extends StatelessWidget {
  const SeparateExportsCard({super.key, required this.controller});

  final DataManagementController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasPeriod = controller.period != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Exportar por separado', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Para cuando solo necesitas un archivo de calificaciones o '
            'de asistencia, sin el resto del periodo completo.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AppListTile(
            icon: Icons.grade_outlined,
            title: 'Calificaciones',
            subtitle: 'Notas del periodo seleccionado, por estudiante.',
            subtitleMaxLines: 2,
            trailing: AppButton(
              label: 'Exportar',
              variant: AppButtonVariant.outlined,
              isLoading: controller.isExporting('grades'),
              onPressed: hasPeriod
                  ? () => controller.exportGrades(context)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          AppListTile(
            icon: Icons.checklist_outlined,
            title: 'Asistencia',
            subtitle: 'Historial de asistencia del periodo seleccionado.',
            subtitleMaxLines: 2,
            trailing: AppButton(
              label: 'Exportar',
              variant: AppButtonVariant.outlined,
              isLoading: controller.isExporting('attendance'),
              onPressed: hasPeriod
                  ? () => controller.exportAttendance(context)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Intake -> selected file + "Importar" -> result summary, the same
/// sequence for every upload card.
class _UploadBlock extends StatelessWidget {
  const _UploadBlock({
    required this.picked,
    required this.intake,
    required this.onPicked,
    required this.uploading,
    required this.onUpload,
    required this.done,
    required this.result,
    required this.onDismissResult,
  });

  final PickedFile? picked;
  final FileIntakeBuilder intake;
  final ValueChanged<PickedFile?> onPicked;
  final bool uploading;
  final VoidCallback? onUpload;
  final bool done;
  final ImportResultEntity? result;
  final VoidCallback onDismissResult;

  @override
  Widget build(BuildContext context) {
    final picked = this.picked;
    final result = this.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (picked == null)
          intake(onPicked)
        else ...[
          AppSelectedFileTile(file: picked, onRemove: () => onPicked(null)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Importar',
            isLoading: uploading,
            onPressed: onUpload,
          ),
        ],
        if (done && result != null) ...[
          const SizedBox(height: 20),
          ImportResultSummary(
            result: result,
            onDownloadErrors: result.batch.hasErrorReport
                ? () => fetchAndSaveFile(
                    context,
                    fetch: () => context
                        .read<ImportsProvider>()
                        .downloadErrorReport(result.batch.id),
                    errorMessage: 'No se pudo descargar el reporte.',
                  )
                : null,
            onDismiss: onDismissResult,
          ),
        ],
      ],
    );
  }
}
