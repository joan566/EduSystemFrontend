import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_status_chip.dart';

/// Callbacks of the table's rows and their menu.
class StudentRowActions {
  const StudentRowActions({
    required this.onSelect,
    required this.onOpen,
    required this.onCopy,
    required this.onWithdraw,
  });

  final ValueChanged<StudentEntity> onSelect;

  /// Opens the student, optionally on a tab (see `RoutePaths.studentDetail`).
  final void Function(StudentEntity student, {int? tab}) onOpen;
  final void Function(String label, String value) onCopy;
  final ValueChanged<StudentEntity> onWithdraw;
}

const _flexStudent = 6;
const _flexCode = 3;
const _flexId = 3;
const _flexCourse = 2;
const _statusWidth = 120.0;
const _menuWidth = 44.0;

/// Dense, hoverable table of the teacher's students. Click selects, double
/// click (or Enter) opens, ↑/↓ move the selection.
class StudentsTable extends StatelessWidget {
  const StudentsTable({
    super.key,
    required this.students,
    required this.selectedStudentId,
    required this.actions,
    required this.clickOpens,
    this.footer,
  });

  final List<StudentEntity> students;
  final int? selectedStudentId;
  final StudentRowActions actions;

  /// Without a preview pane beside the table, a single click opens the
  /// student instead of just selecting them.
  final bool clickOpens;

  /// Below the rows, e.g. pagination.
  final Widget? footer;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (students.isEmpty) return KeyEventResult.ignored;
    final index = students.indexWhere((s) => s.id == selectedStudentId);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      actions.onSelect(students[(index + 1).clamp(0, students.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      actions.onSelect(students[(index - 1).clamp(0, students.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && index >= 0) {
      actions.onOpen(students[index]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Focus(
      onKeyEvent: _onKey,
      child: Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _HeaderRow(),
              Divider(height: 1, color: colors.outline),
              Expanded(
                child: ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outline),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _Row(
                      student: student,
                      selected: student.id == selectedStudentId,
                      actions: actions,
                      onTap: () {
                        Focus.of(context).requestFocus();
                        clickOpens
                            ? actions.onOpen(student)
                            : actions.onSelect(student);
                      },
                    );
                  },
                ),
              ),
              if (footer != null) ...[
                Divider(height: 1, color: colors.outline),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text.toUpperCase(), style: style),
    );

    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          cell('Estudiante', _flexStudent),
          cell('Código', _flexCode),
          cell('Identificación', _flexId),
          cell('Curso', _flexCourse),
          SizedBox(
            width: _statusWidth,
            child: Text('ESTADO', style: style),
          ),
          const SizedBox(width: _menuWidth),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.student,
    required this.selected,
    required this.actions,
    required this.onTap,
  });

  final StudentEntity student;
  final bool selected;
  final StudentRowActions actions;
  final VoidCallback onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enrollment = student.currentEnrollment;
    final tabular = textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final background = widget.selected
        ? AppColors.accentBlue.withValues(alpha: 0.07)
        : _hovering
        ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: background,
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: () => widget.actions.onOpen(student),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected
                      ? AppColors.accentBlue
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(17, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  flex: _flexStudent,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accentBlue.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          student.initials,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              student.email.isEmpty
                                  ? 'Sin correo'
                                  : student.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexCode,
                  child: Text(student.studentCode, style: tabular),
                ),
                Expanded(
                  flex: _flexId,
                  child: Text(
                    student.identificationNumber.isEmpty
                        ? '—'
                        : student.identificationNumber,
                    style: tabular,
                  ),
                ),
                Expanded(
                  flex: _flexCourse,
                  child: Text(
                    enrollment?.courseLabel ?? '—',
                    style: textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: _statusWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StudentStatusChip(enrollment: enrollment),
                    ),
                  ),
                ),
                SizedBox(
                  width: _menuWidth,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovering || widget.selected ? 1 : 0.35,
                    child: _RowMenu(student: student, actions: widget.actions),
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

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.student, required this.actions});

  final StudentEntity student;
  final StudentRowActions actions;

  @override
  Widget build(BuildContext context) {
    final enrollment = student.currentEnrollment;
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (value) => switch (value) {
        0 => actions.onOpen(student),
        1 => actions.onOpen(student, tab: 2),
        2 => actions.onCopy('Código', student.studentCode),
        3 => actions.onCopy('Correo', student.email),
        _ => actions.onWithdraw(student),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('Abrir ficha')),
        const PopupMenuItem(value: 1, child: Text('Ver notas')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 2, child: Text('Copiar código')),
        if (student.email.isNotEmpty)
          const PopupMenuItem(value: 3, child: Text('Copiar correo')),
        if (enrollment != null && enrollment.active) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 4,
            child: Text('Retirar de ${enrollment.courseLabel}'),
          ),
        ],
      ],
    );
  }
}
