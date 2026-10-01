import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../../core/widgets/shared/app_text_field.dart';
import '../../../academic_levels/domain/entities/academic_level_entity.dart';
import '../../domain/entities/course_entity.dart';

/// Values submitted by [CourseForm].
typedef CourseFormResult = ({int gradeId, String name, int academicYear});

/// Create/edit form for a course. Platform-agnostic: each view opens it
/// with its own presenter, which supplies the [AppFormFrame] chrome.
class CourseForm extends StatefulWidget {
  const CourseForm({
    super.key,
    required this.onSubmit,
    this.initial,
    required this.levels,
  });

  /// Saves the values; the form stays open with its button loading until
  /// it completes and closes only on success, so a failed save keeps
  /// what was typed.
  final Future<bool> Function(CourseFormResult) onSubmit;

  final CourseEntity? initial;
  final List<AcademicLevelEntity> levels;

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  late final _yearController = TextEditingController(
    text: (widget.initial?.academicYear ?? DateTime.now().year).toString(),
  );
  int? _gradeId;

  @override
  void initState() {
    super.initState();
    _gradeId =
        widget.initial?.gradeId ??
        (widget.levels.isNotEmpty ? widget.levels.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gradeId == null) return;
    final CourseFormResult data = (
      gradeId: _gradeId!,
      name: _nameController.text.trim(),
      academicYear: int.parse(_yearController.text.trim()),
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
      title: isEditing ? 'Editar curso' : 'Nuevo curso',
      actions: [
        AppButton(label: 'Guardar', isLoading: _saving, onPressed: _submit),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Grado',
              required: true,
              value: _gradeId,
              enabled: !isEditing,
              helperText: isEditing
                  ? 'El grado no se puede cambiar después de crear el curso.'
                  : null,
              items: [for (final level in widget.levels) level.id],
              itemLabel: (id) =>
                  widget.levels.firstWhere((l) => l.id == id).name,
              onChanged: (value) => setState(() => _gradeId = value),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nombre del curso',
              required: true,
              hint: 'Ej. A',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 50, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _yearController,
              label: 'Año académico',
              required: true,
              keyboardType: TextInputType.number,
              validator: (v) {
                final year = int.tryParse(v ?? '');
                if (year == null || year < 2000 || year > 2200) {
                  return 'Ingresa un año válido (2000-2200).';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
