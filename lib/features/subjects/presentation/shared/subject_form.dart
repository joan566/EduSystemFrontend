import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/subject_entity.dart';

/// Values submitted by [SubjectForm].
typedef SubjectFormResult = ({String name, String description});

/// Create/edit form for a subject. Platform-agnostic: each view opens it
/// with its own presenter, which supplies the [AppFormFrame] chrome.
class SubjectForm extends StatefulWidget {
  const SubjectForm({super.key, required this.onSubmit, this.initial});

  /// Saves the values; the form stays open with its button loading until
  /// it completes and closes only on success, so a failed save keeps
  /// what was typed.
  final Future<bool> Function(SubjectFormResult) onSubmit;

  final SubjectEntity? initial;

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
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
    final SubjectFormResult data = (
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
      title: isEditing ? 'Editar materia' : 'Nueva materia',
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
              hint: 'Ej. Matemáticas',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 100, field: 'El nombre'),
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
