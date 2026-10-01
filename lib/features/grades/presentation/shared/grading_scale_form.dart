import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';

/// Values submitted by [GradingScaleForm].
typedef GradingScaleFormResult = ({
  String name,
  double minimumValue,
  double maximumValue,
});

/// Create form for a grading scale. Platform-agnostic: each view opens it
/// with its own presenter, which supplies the [AppFormFrame] chrome.
class GradingScaleForm extends StatefulWidget {
  const GradingScaleForm({super.key, required this.onSubmit});

  /// Saves the values; the form stays open with its button loading until
  /// it completes and closes only on success, so a failed save keeps
  /// what was typed.
  final Future<bool> Function(GradingScaleFormResult) onSubmit;

  @override
  State<GradingScaleForm> createState() => _GradingScaleFormState();
}

class _GradingScaleFormState extends State<GradingScaleForm> {
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minController = TextEditingController(text: '0');
  final _maxController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final min = double.parse(_minController.text.trim());
    final max = double.parse(_maxController.text.trim());
    if (min >= max) {
      context.showWarning('El mínimo debe ser menor que el máximo.');
      return;
    }
    final GradingScaleFormResult data = (
      name: _nameController.text.trim(),
      minimumValue: min,
      maximumValue: max,
    );
    setState(() => _saving = true);
    final ok = await widget.onSubmit(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Nueva escala',
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
              hint: 'Ej. Escala 0-5',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _minController,
                    label: 'Mínimo',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _maxController,
                    label: 'Máximo',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
