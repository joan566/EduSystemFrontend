import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';

class ExamEditDialog extends StatefulWidget {
  const ExamEditDialog({super.key, required this.exam});

  final ExamEntity exam;

  @override
  State<ExamEditDialog> createState() => _ExamEditDialogState();
}

class _ExamEditDialogState extends State<ExamEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.exam.name);
  late final _descriptionController = TextEditingController(
    text: widget.exam.description,
  );
  DateTime? _evaluationDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _evaluationDate = widget.exam.evaluationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _evaluationDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_evaluationDate ?? now),
    );
    setState(() {
      _evaluationDate = time == null
          ? date
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<ExamsProvider>().updateMetadata(
      widget.exam.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      evaluationDate: _evaluationDate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showApiError(error);
    } else {
      Navigator.of(context).pop();
      context.showSuccess('Examen actualizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Editar examen',
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
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 150, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Descripción',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del examen',
                ),
                child: Text(
                  _evaluationDate == null
                      ? 'Seleccionar'
                      : Formatters.dateTime(_evaluationDate!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
