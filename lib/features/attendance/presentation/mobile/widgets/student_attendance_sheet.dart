import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../shared/attendance_day_controller.dart';
import '../../shared/attendance_visuals.dart';

/// Floating sheet to set one student's attendance (status and an optional
/// observation). It only changes the local marks; nothing is sent until the
/// screen saves them all together.
Future<void> showStudentAttendanceSheet(
  BuildContext context, {
  required AttendanceDayController controller,
  required SessionStudentRecord student,
  required String detail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StudentAttendanceSheet(
      controller: controller,
      student: student,
      detail: detail,
    ),
  );
}

class _StudentAttendanceSheet extends StatefulWidget {
  const _StudentAttendanceSheet({
    required this.controller,
    required this.student,
    required this.detail,
  });

  final AttendanceDayController controller;
  final SessionStudentRecord student;

  /// "5° A · Aula 3".
  final String detail;

  @override
  State<_StudentAttendanceSheet> createState() =>
      _StudentAttendanceSheetState();
}

class _StudentAttendanceSheetState extends State<_StudentAttendanceSheet> {
  late AttendanceStatus? _status = widget.controller.statusOf(
    widget.student.studentId,
  );
  late final _observation = TextEditingController(
    text: widget.controller.observationOf(widget.student.studentId) ?? '',
  );
  late bool _editingObservation = _observation.text.isNotEmpty;

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  /// Only updates the local marks; the screen's "Guardar asistencia" sends
  /// every change in one request.
  void _apply() {
    final status = _status;
    if (status == null) return;
    final observation = _observation.text.trim();
    widget.controller.mark(
      widget.student.studentId,
      status,
      observation: observation.isEmpty ? null : observation,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final saved = widget.controller.statusOf(widget.student.studentId);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.accentBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.studentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.detail,
                          style: textTheme.bodyMedium?.copyWith(
                            color: textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AttendanceStatusPill(status: saved),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.outline),
              const SizedBox(height: 16),
              Text('Estado de asistencia', style: textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, status)
                      in AttendanceStatus.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _StatusOption(
                        status: status,
                        selected: _status == status,
                        onTap: () => setState(() => _status = status),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _ObservationField(
                controller: _observation,
                editing: _editingObservation,
                onStartEditing: () =>
                    setState(() => _editingObservation = true),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Aplicar',
                icon: Icons.check,
                expand: true,
                onPressed: _status == null || widget.controller.saving
                    ? null
                    : _apply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visuals = attendanceVisuals(status);
    final color = visuals.color;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: color.withValues(alpha: selected ? 0.1 : 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? AppColors.accentBlue
                : color.withValues(alpha: 0.18),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected && status == AttendanceStatus.present
                        ? AppColors.accentBlue
                        : color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visuals.icon, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      visuals.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObservationField extends StatelessWidget {
  const _ObservationField({
    required this.controller,
    required this.editing,
    required this.onStartEditing,
  });

  final TextEditingController controller;
  final bool editing;
  final VoidCallback onStartEditing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.color;

    if (editing) {
      return TextField(
        controller: controller,
        autofocus: controller.text.isEmpty,
        maxLength: 255,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Observación (opcional)',
          hintText: 'Por ejemplo: llegó tarde, cita médica…',
          prefixIcon: Icon(Icons.sticky_note_2_outlined),
        ),
      );
    }
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onStartEditing,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, size: 20, color: muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Agregar observación (opcional)',
                  style: textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
