import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/teaching_assignment_entity.dart';
import 'class_labels.dart';

/// Values submitted by [AddClassesForm]. [academicPeriodId] is null when
/// the subjects are only assigned, with no class in a period yet.
typedef AddClassesResult = ({
  int groupId,
  List<int> subjectIds,
  int? academicPeriodId,
});

/// "Agregar materias": the subjects the teacher teaches in a course, and
/// the academic period their classes start in. Subjects already taught in
/// the course show as such; they get their class in the period too.
class AddClassesForm extends StatefulWidget {
  const AddClassesForm({
    super.key,
    required this.courses,
    required this.subjects,
    required this.academicPeriods,
    required this.assignments,
    required this.onSubmit,
    this.initialGroupId,
    this.initialAcademicPeriodId,
  });

  /// Adds the classes; the form stays open with its button loading until
  /// it completes and closes only on success.
  final Future<bool> Function(AddClassesResult) onSubmit;

  final List<CourseEntity> courses;
  final List<SubjectEntity> subjects;
  final List<AcademicPeriodEntity> academicPeriods;

  /// The teacher's assignments, to mark subjects already in a course.
  final List<TeachingAssignmentEntity> assignments;

  final int? initialGroupId;
  final int? initialAcademicPeriodId;

  @override
  State<AddClassesForm> createState() => _AddClassesFormState();
}

class _AddClassesFormState extends State<AddClassesForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late int? _groupId =
      widget.courses
          .where((c) => c.id == widget.initialGroupId)
          .firstOrNull
          ?.id ??
      _sortedCourses.firstOrNull?.id;
  late int? _academicPeriodId = widget.initialAcademicPeriodId;
  final _subjectIds = <int>{};
  bool _showSubjectError = false;

  late final List<CourseEntity> _sortedCourses = [...widget.courses]
    ..sort((a, b) {
      final byYear = b.academicYear.compareTo(a.academicYear);
      if (byYear != 0) return byYear;
      final byGrade = compareGradeNames(a.gradeName, b.gradeName);
      return byGrade != 0
          ? byGrade
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  late final Map<int, String> _courseLabels = courseLabels([
    for (final c in widget.courses)
      (
        groupId: c.id,
        gradeName: c.gradeName,
        groupName: c.name,
        academicYear: c.academicYear,
      ),
  ]);

  Set<int> get _assignedSubjects => {
    for (final a in widget.assignments)
      if (a.groupId == _groupId) a.subjectId,
  };

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showSubjectError = _subjectIds.isEmpty);
    if (!valid || _subjectIds.isEmpty || _groupId == null) return;
    setState(() => _saving = true);
    final ok = await widget.onSubmit((
      groupId: _groupId!,
      subjectIds: _subjectIds.toList(),
      academicPeriodId: _academicPeriodId,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final assigned = _assignedSubjects;

    return AppFormFrame(
      title: 'Agregar materias a un curso',
      actions: [
        AppButton(label: 'Guardar', isLoading: _saving, onPressed: _submit),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Curso',
              required: true,
              value: _groupId,
              items: [for (final c in _sortedCourses) c.id],
              itemLabel: (id) => _courseLabels[id]!,
              validator: (v) => v == null ? 'Selecciona un curso.' : null,
              onChanged: (value) => setState(() {
                _groupId = value;
                _subjectIds.clear();
              }),
            ),
            const SizedBox(height: 18),
            Text(
              'Materias que dictas en este curso *',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in widget.subjects)
                  FilterChip(
                    label: Text(s.name),
                    selected: _subjectIds.contains(s.id),
                    selectedColor: AppColors.accentBlue.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.accentBlue,
                    avatar:
                        assigned.contains(s.id) && !_subjectIds.contains(s.id)
                        ? const Icon(Icons.check_circle_outline, size: 16)
                        : null,
                    tooltip: assigned.contains(s.id)
                        ? 'Ya la dictas en este curso'
                        : null,
                    onSelected: (on) => setState(() {
                      on ? _subjectIds.add(s.id) : _subjectIds.remove(s.id);
                      _showSubjectError = false;
                    }),
                  ),
              ],
            ),
            if (_showSubjectError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Elige al menos una materia.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (assigned.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Las marcadas con ✓ ya las dictas aquí: elegirlas solo crea '
                  'su clase en el periodo, si falta.',
                  style: textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 18),
            AppDropdown<int?>(
              label: 'Periodo académico',
              value: _academicPeriodId,
              items: [null, for (final p in widget.academicPeriods) p.id],
              itemLabel: (id) => id == null
                  ? 'Ninguno por ahora'
                  : widget.academicPeriods.firstWhere((p) => p.id == id).name,
              helperText:
                  'Se crea la clase de cada materia en este periodo, lista '
                  'para su horario, asistencia y notas.',
              onChanged: (value) => setState(() => _academicPeriodId = value),
            ),
          ],
        ),
      ),
    );
  }
}
