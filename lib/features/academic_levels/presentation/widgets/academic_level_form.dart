import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/academic_level_entity.dart';

/// Create/edit form for an academic level ("grado"), shown via
/// [showAppDialog] (dialog on desktop, full-screen on mobile).
class AcademicLevelForm extends StatefulWidget {
  const AcademicLevelForm({super.key, this.initial});

  final AcademicLevelEntity? initial;

  @override
  State<AcademicLevelForm> createState() => _AcademicLevelFormState();
}

class _AcademicLevelFormState extends State<AcademicLevelForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.name);
  late final _descriptionController =
      TextEditingController(text: widget.initial?.description);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppDialogFrame(
      title: isEditing ? 'Editar grado' : 'Nuevo grado',
      actions: [
        AppButton(label: 'Guardar', onPressed: _submit),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Nombre',
              required: true,
              hint: 'Ej. 10°',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 50, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Descripción',
              maxLines: 2,
              validator: (v) => Validators.maxLength(v, 255, field: 'La descripción'),
            ),
          ],
        ),
      ),
    );
  }
}
