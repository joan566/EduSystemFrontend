import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../domain/entities/schedule_entities.dart';

/// Values submitted by [ClassScheduleForm].
typedef ClassScheduleFormResult = ({
  int dayOfWeek,
  ClockTime startTime,
  ClockTime endTime,
  String room,
});

/// Create/edit one weekly block of a class (day, start, end, room).
/// Platform-agnostic: each view presents it with its own [AppFormFrame].
class ClassScheduleForm extends StatefulWidget {
  const ClassScheduleForm({super.key, this.initial});

  final ClassScheduleEntity? initial;

  @override
  State<ClassScheduleForm> createState() => _ClassScheduleFormState();
}

class _ClassScheduleFormState extends State<ClassScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late int _dayOfWeek = widget.initial?.dayOfWeek ?? DateTime.monday;
  late ClockTime _start = widget.initial?.startTime ?? const ClockTime(7, 0);
  late ClockTime _end = widget.initial?.endTime ?? const ClockTime(8, 0);
  late final _roomController = TextEditingController(
    text: widget.initial?.room,
  );

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final value = ClockTime(picked.hour, picked.minute);
    setState(() => isStart ? _start = value : _end = value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_end.compareTo(_start) <= 0) {
      context.showWarning('La hora de fin debe ser posterior a la de inicio.');
      return;
    }
    Navigator.of(context).pop<ClassScheduleFormResult>((
      dayOfWeek: _dayOfWeek,
      startTime: _start,
      endTime: _end,
      room: _roomController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: widget.initial == null ? 'Agregar bloque' : 'Editar bloque',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Día',
              required: true,
              value: _dayOfWeek,
              items: const [1, 2, 3, 4, 5, 6, 7],
              itemLabel: Formatters.weekdayName,
              onChanged: (value) =>
                  setState(() => _dayOfWeek = value ?? _dayOfWeek),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Inicio',
                    value: _start,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'Fin',
                    value: _end,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _roomController,
              label: 'Salón (opcional)',
              hint: 'Ej. Aula 204',
              validator: (v) => Validators.maxLength(v, 50, field: 'El salón'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final ClockTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          suffixIcon: const Icon(Icons.schedule, size: 18),
        ),
        child: Text(value.format()),
      ),
    );
  }
}
