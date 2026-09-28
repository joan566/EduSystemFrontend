import 'package:flutter/material.dart';

import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_form_frame.dart';
import '../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/teaching_assignment_entity.dart';

/// Values submitted by [AssignmentForm].
typedef AssignmentFormResult = ({int groupId, int subjectId});

/// Values submitted by [TeachingPeriodForm].
typedef TeachingPeriodFormResult = ({
  int teachingAssignmentId,
  int academicPeriodId,
});

/// Links a subject to a course (a "asignación").
class AssignmentForm extends StatefulWidget {
  const AssignmentForm({
    super.key,
    required this.subjects,
    required this.courses,
  });

  final List<SubjectEntity> subjects;
  final List<CourseEntity> courses;

  @override
  State<AssignmentForm> createState() => AssignmentFormStateX();
}

class AssignmentFormStateX extends State<AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  int? _subjectId;
  int? _groupId;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjects.first.id;
    _groupId = widget.courses.first.id;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop<AssignmentFormResult>((groupId: _groupId!, subjectId: _subjectId!));
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Nueva asignación',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Materia',
              required: true,
              value: _subjectId,
              items: [for (final s in widget.subjects) s.id],
              itemLabel: (id) =>
                  widget.subjects.firstWhere((s) => s.id == id).name,
              validator: (v) => v == null ? 'Selecciona una materia.' : null,
              onChanged: (value) => setState(() => _subjectId = value),
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'Curso',
              required: true,
              value: _groupId,
              items: [for (final c in widget.courses) c.id],
              itemLabel: (id) =>
                  widget.courses.firstWhere((c) => c.id == id).displayName,
              validator: (v) => v == null ? 'Selecciona un curso.' : null,
              onChanged: (value) => setState(() => _groupId = value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Links an active assignment to an academic period (a "clase").
class TeachingPeriodForm extends StatefulWidget {
  const TeachingPeriodForm({
    super.key,
    required this.assignments,
    required this.periods,
  });

  final List<TeachingAssignmentEntity> assignments;
  final List<AcademicPeriodEntity> periods;

  @override
  State<TeachingPeriodForm> createState() => _TeachingPeriodFormState();
}

class _TeachingPeriodFormState extends State<TeachingPeriodForm> {
  final _formKey = GlobalKey<FormState>();
  int? _assignmentId;
  int? _periodId;

  @override
  void initState() {
    super.initState();
    _assignmentId = widget.assignments.first.id;
    _periodId = widget.periods.first.id;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<TeachingPeriodFormResult>((
      teachingAssignmentId: _assignmentId!,
      academicPeriodId: _periodId!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppFormFrame(
      title: 'Nueva clase',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: 'Asignación',
              required: true,
              value: _assignmentId,
              items: [for (final a in widget.assignments) a.id],
              itemLabel: (id) =>
                  widget.assignments.firstWhere((a) => a.id == id).displayName,
              validator: (v) => v == null ? 'Selecciona una asignación.' : null,
              onChanged: (value) => setState(() => _assignmentId = value),
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'Periodo académico',
              required: true,
              value: _periodId,
              items: [for (final p in widget.periods) p.id],
              itemLabel: (id) =>
                  widget.periods.firstWhere((p) => p.id == id).name,
              validator: (v) => v == null ? 'Selecciona un periodo.' : null,
              onChanged: (value) => setState(() => _periodId = value),
            ),
          ],
        ),
      ),
    );
  }
}
