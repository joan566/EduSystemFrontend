import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';

/// Values submitted by [ActivityForm].
typedef ActivityFormResult = ({
  String name,
  String activityType,
  double maximumScore,
});

/// Create form for an activity. Platform-agnostic: each view opens it with
/// its own presenter, which supplies the [AppFormFrame] chrome.
class ActivityForm extends StatefulWidget {
  const ActivityForm({super.key, required this.onSubmit});

  /// Saves the values; the form stays open with its button loading until
  /// it completes and closes only on success, so a failed save keeps
  /// what was typed.
  final Future<int?> Function(ActivityFormResult) onSubmit;

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ActivityFormResult data = (
      name: _nameController.text.trim(),
      activityType: _typeController.text.trim(),
      maximumScore: double.parse(_maxScoreController.text.trim()),
    );
    setState(() => _saving = true);
    final result = await widget.onSubmit(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Nueva actividad',
      actions: [
        AppButton(label: 'Crear', isLoading: _saving, onPressed: _submit),
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
              hint: 'Ej. Taller de fracciones',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 150, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _typeController,
              label: 'Tipo (opcional)',
              hint: 'Taller, proyecto, quiz...',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _maxScoreController,
              label: 'Puntaje máximo',
              required: true,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Ingresa un puntaje válido.';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
