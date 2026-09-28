import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/academic_period_entity.dart';

/// Values submitted by [AcademicPeriodForm].
typedef AcademicPeriodFormResult = ({
  String name,
  DateTime startDate,
  DateTime endDate,
});

/// Create/edit form for an academic period. Platform-agnostic: each view
/// opens it with its own presenter, which supplies the [AppFormFrame] chrome.
class AcademicPeriodForm extends StatefulWidget {
  const AcademicPeriodForm({super.key, this.initial});

  final AcademicPeriodEntity? initial;

  @override
  State<AcademicPeriodForm> createState() => _AcademicPeriodFormState();
}

class _AcademicPeriodFormState extends State<AcademicPeriodForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial?.startDate;
    _endDate = widget.initial?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      context.showWarning('Selecciona la fecha de inicio y fin.');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      context.showWarning('La fecha de fin debe ser posterior a la de inicio.');
      return;
    }
    Navigator.of(context).pop<AcademicPeriodFormResult>((
      name: _nameController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppFormFrame(
      title: isEditing ? 'Editar periodo' : 'Nuevo periodo',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Nombre',
              required: true,
              hint: 'Ej. Primer periodo 2026',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 100, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Fecha de inicio',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Fecha de fin',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: '$label *'),
        child: Text(date == null ? 'Seleccionar' : Formatters.date(date!)),
      ),
    );
  }
}
