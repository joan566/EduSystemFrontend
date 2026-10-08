import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../providers/exams_provider.dart';
import 'exam_import_controller.dart';

/// Shared document-import content; each platform supplies its own file intake.
class ExamImportForm extends StatelessWidget {
  const ExamImportForm({
    super.key,
    required this.controller,
    required this.fileIntake,
  });

  final ExamImportController controller;
  final Widget fileIntake;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamsProvider>();
    final uploading = provider.importingDocument;
    final file = controller.file;

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Importar examen desde Word',
            style: context.textStyles.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Sube un documento .docx con preguntas de selección múltiple. '
            'Puedes descargar la plantilla para consultar el formato.',
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Descargar plantilla .docx',
            icon: Icons.download_outlined,
            variant: AppButtonVariant.outlined,
            isLoading: controller.downloadingTemplate,
            onPressed: () => controller.downloadTemplate(context),
          ),
          const SizedBox(height: 20),
          Text('Documento', style: context.textStyles.titleMedium),
          const SizedBox(height: 8),
          if (file == null)
            fileIntake
          else
            AppSelectedFileTile(
              file: file,
              onRemove: uploading ? () {} : controller.clearFile,
            ),
          const SizedBox(height: 20),
          Text('Datos del examen', style: context.textStyles.titleMedium),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller.nameController,
            label: 'Nombre (opcional)',
            hint: 'Si lo dejas vacío se usará el nombre del archivo.',
            enabled: !uploading,
            maxLength: 150,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller.descriptionController,
            label: 'Descripción (opcional)',
            enabled: !uploading,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: uploading ? null : () => controller.pickDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha y hora (opcional)',
                suffixIcon: controller.evaluationDate == null
                    ? const Icon(Icons.calendar_month_outlined)
                    : IconButton(
                        tooltip: 'Quitar fecha',
                        onPressed: uploading ? null : controller.clearDate,
                        icon: const Icon(Icons.close),
                      ),
              ),
              child: Text(
                controller.evaluationDate == null
                    ? 'Seleccionar'
                    : Formatters.dateTime(controller.evaluationDate!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller.maximumScoreController,
            label: 'Puntaje máximo (opcional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: controller.validateMaximumScore,
            enabled: !uploading,
          ),
          if (controller.validationError case final error?) ...[
            const SizedBox(height: 16),
            _ImportValidationErrors(
              messages: [
                for (final fieldError in error.fieldErrors) fieldError.message,
              ],
            ),
          ],
          if (uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: provider.documentImportProgress),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: uploading ? 'Importando examen…' : 'Importar examen',
            icon: Icons.upload_file_outlined,
            expand: true,
            isLoading: uploading,
            onPressed: file == null ? null : () => controller.import(context),
          ),
        ],
      ),
    );
  }
}

class _ImportValidationErrors extends StatelessWidget {
  const _ImportValidationErrors({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revisa el documento:',
            style: TextStyle(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $message',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
        ],
      ),
    );
  }
}
