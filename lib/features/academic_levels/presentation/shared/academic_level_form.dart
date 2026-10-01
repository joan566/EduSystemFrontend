import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/academic_level_entity.dart';

/// Values submitted by [AcademicLevelForm].
typedef AcademicLevelFormResult = ({String name, String description});

/// Create/edit form for an academic level ("grado"). Platform-agnostic:
/// the desktop view opens it in a dialog, the mobile view as a full-screen
/// route; [AppFormFrame] takes the chrome from whichever opened it.
class AcademicLevelForm extends StatefulWidget {
  const AcademicLevelForm({super.key, required this.onSubmit, this.initial});

  /// Saves the values; the form stays open with its button loading until
  /// it completes and closes only on success, so a failed save keeps
  /// what was typed.
  final Future<bool> Function(AcademicLevelFormResult) onSubmit;

  final AcademicLevelEntity? initial;

  @override
  State<AcademicLevelForm> createState() => _AcademicLevelFormState();
}

class _AcademicLevelFormState extends State<AcademicLevelForm> {
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.initial?.description,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final AcademicLevelFormResult data = (
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    setState(() => _saving = true);
    final ok = await widget.onSubmit(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppFormFrame(
      title: isEditing ? 'Editar grado' : 'Nuevo grado',
      actions: [
        AppButton(label: 'Guardar', isLoading: _saving, onPressed: _submit),
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
              validator: (v) =>
                  Validators.maxLength(v, 255, field: 'La descripción'),
            ),
          ],
        ),
      ),
    );
  }
}
