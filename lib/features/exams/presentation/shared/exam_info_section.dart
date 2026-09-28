import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_text_field.dart';

/// Step 1 of [ExamBuilderPage]: the exam's own metadata, decoupled from its
/// questions. Deliberately does NOT collect a question count anymore — the
/// Preguntas step lets the user add/remove questions freely, so asking for
/// a number upfront (as the old `ExamForm` did) is no longer needed and
/// would just be a number the user has to guess before writing anything.
class ExamInfoSection extends StatelessWidget {
  const ExamInfoSection({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.maxScoreController,
    required this.evaluationDate,
    required this.onPickDate,
    required this.saving,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController maxScoreController;
  final DateTime? evaluationDate;
  final VoidCallback onPickDate;
  final bool saving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Información del examen', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Estos datos aparecen en la hoja de respuesta y en los reportes.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: nameController,
              label: 'Nombre del examen',
              required: true,
              hint: 'Ej. Parcial 1',
              helperText:
                  'Este nombre lo verán tus estudiantes en la hoja de respuesta.',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 150, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              label: 'Descripción (opcional)',
              maxLines: 2,
              helperText: 'Instrucciones o contexto adicional para el examen.',
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onPickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del examen (opcional)',
                ),
                child: Text(
                  evaluationDate == null
                      ? 'Seleccionar'
                      : Formatters.dateTime(evaluationDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: maxScoreController,
              label: 'Puntaje máximo (opcional)',
              keyboardType: TextInputType.number,
              helperText:
                  'Se comparará con la suma de los puntos de las preguntas al revisar.',
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Continuar',
                isLoading: saving,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
