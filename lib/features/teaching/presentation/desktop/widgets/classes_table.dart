import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../../domain/entities/teaching_assignment_entity.dart';
import '../../../domain/entities/teaching_period_entity.dart';
import '../../shared/class_lookup.dart';

/// One table row: an assignment and its class in the chosen period.
class ClassRowData {
  const ClassRowData({
    required this.assignment,
    required this.period,
    required this.description,
    required this.weeklySessions,
  });

  final TeachingAssignmentEntity assignment;

  /// Its class in the chosen academic period; null when it has none.
  final TeachingPeriodEntity? period;
  final String? description;

  /// Sessions in the coming week; null while unknown.
  final int? weeklySessions;
}

/// Callbacks of the table's row actions.
class ClassRowActions {
  const ClassRowActions({
    required this.onSelect,
    required this.onOpen,
    required this.onCreateClass,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ValueChanged<ClassRowData> onSelect;
  final ValueChanged<ClassRowData> onOpen;
  final ValueChanged<ClassRowData> onCreateClass;
  final ValueChanged<ClassRowData> onToggleActive;
  final ValueChanged<ClassRowData> onDelete;
}

const _flexClass = 5;
const _flexPeriod = 3;
const _flexSchedule = 2;
const _flexStudents = 2;
const _activeWidth = 76.0;
const _menuWidth = 44.0;

/// Dense, hoverable table of the teacher's classes. Click selects, double
/// click (or Enter) opens, ↑/↓ move the selection.
class ClassesTable extends StatelessWidget {
  const ClassesTable({
    super.key,
    required this.rows,
    required this.selectedAssignmentId,
    required this.academicPeriod,
    required this.actions,
    required this.clickOpens,
  });

  final List<ClassRowData> rows;
  final int? selectedAssignmentId;
  final AcademicPeriodEntity? academicPeriod;
  final ClassRowActions actions;

  /// Without a preview pane beside the table, a single click opens the
  /// class instead of just selecting it.
  final bool clickOpens;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (rows.isEmpty) return KeyEventResult.ignored;
    final index = rows.indexWhere(
      (r) => r.assignment.id == selectedAssignmentId,
    );
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      actions.onSelect(rows[(index + 1).clamp(0, rows.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      actions.onSelect(rows[(index - 1).clamp(0, rows.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && index >= 0) {
      actions.onOpen(rows[index]);
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
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outline),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _Row(
                      row: row,
                      selected: row.assignment.id == selectedAssignmentId,
                      academicPeriod: academicPeriod,
                      actions: actions,
                      onTap: () {
                        Focus.of(context).requestFocus();
                        clickOpens
                            ? actions.onOpen(row)
                            : actions.onSelect(row);
                      },
                    );
                  },
                ),
              ),
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
          cell('Clase', _flexClass),
          cell('En el periodo', _flexPeriod),
          cell('Horario', _flexSchedule),
          cell('Alumnos', _flexStudents),
          SizedBox(
            width: _activeWidth,
            child: Text('ACTIVA', style: style),
          ),
          const SizedBox(width: _menuWidth),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.row,
    required this.selected,
    required this.academicPeriod,
    required this.actions,
    required this.onTap,
  });

  final ClassRowData row;
  final bool selected;
  final AcademicPeriodEntity? academicPeriod;
  final ClassRowActions actions;
  final VoidCallback onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final a = row.assignment;
    final period = row.period;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall;

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
          onDoubleTap: period == null ? null : () => widget.actions.onOpen(row),
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
            padding: const EdgeInsets.fromLTRB(17, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  flex: _flexClass,
                  child: Row(
                    children: [
                      TintedIcon(
                        icon: subjectIcon(a.subjectName),
                        color: subjectAccent(a.subjectId),
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${a.subjectName} — ${a.gradeName} ${a.groupName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (row.description != null)
                              Text(
                                row.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: muted,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexPeriod,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _PeriodCell(
                      row: row,
                      academicPeriod: widget.academicPeriod,
                      onCreate: () => widget.actions.onCreateClass(row),
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexSchedule,
                  child: Text(
                    period == null
                        ? '—'
                        : switch (row.weeklySessions) {
                            null => '—',
                            0 => 'Sin horario',
                            1 => '1 clase/sem',
                            final n => '$n clases/sem',
                          },
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: _flexStudents,
                  child: Text(
                    period == null ? '—' : '${period.studentCount}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: _activeWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: a.active,
                        onChanged: (_) => widget.actions.onToggleActive(row),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _menuWidth,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovering || widget.selected ? 1 : 0.35,
                    child: _RowMenu(
                      row: row,
                      academicPeriod: widget.academicPeriod,
                      actions: widget.actions,
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

class _PeriodCell extends StatelessWidget {
  const _PeriodCell({
    required this.row,
    required this.academicPeriod,
    required this.onCreate,
  });

  final ClassRowData row;
  final AcademicPeriodEntity? academicPeriod;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final period = row.period;
    if (period == null) {
      if (academicPeriod == null) {
        return Text('Sin clases', style: Theme.of(context).textTheme.bodySmall);
      }
      return TextButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Crear clase'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    final (label, kind) = switch (classPeriodStatus(period, DateTime.now())) {
      ClassPeriodStatus.active => ('En curso', AppStatusKind.success),
      ClassPeriodStatus.upcoming => ('Próxima', AppStatusKind.info),
      ClassPeriodStatus.finished => ('Finalizada', AppStatusKind.neutral),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppStatusChip(label: label, kind: kind),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            period.academicPeriodName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.row,
    required this.academicPeriod,
    required this.actions,
  });

  final ClassRowData row;
  final AcademicPeriodEntity? academicPeriod;
  final ClassRowActions actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (value) => switch (value) {
        0 => actions.onOpen(row),
        1 => actions.onCreateClass(row),
        2 => actions.onToggleActive(row),
        _ => actions.onDelete(row),
      },
      itemBuilder: (context) => [
        if (row.period != null)
          const PopupMenuItem(value: 0, child: Text('Abrir clase')),
        if (row.period == null && academicPeriod != null)
          PopupMenuItem(
            value: 1,
            child: Text('Crear clase en ${academicPeriod!.name}'),
          ),
        PopupMenuItem(
          value: 2,
          child: Text(
            row.assignment.active
                ? 'Desactivar asignación'
                : 'Activar asignación',
          ),
        ),
        const PopupMenuItem(value: 3, child: Text('Eliminar asignación')),
      ],
    );
  }
}
