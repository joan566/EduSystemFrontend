import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/grading_entities.dart';
import '../../shared/category_visuals.dart';
import '../../shared/grade_labels.dart';
import '../../shared/initials.dart';

const _flexStudent = 5;
const _flexCategory = 2;
const _flexFinal = 3;
const _statusWidth = 116.0;
const _chevronWidth = 32.0;

/// The class gradebook: one row per student with each component's grade,
/// the final grade and the status. Click selects, double click (or Enter)
/// opens, ↑/↓ move the selection.
class GradesTable extends StatelessWidget {
  const GradesTable({
    super.key,
    required this.data,
    required this.students,
    required this.selectedStudentId,
    required this.onSelect,
    required this.onOpen,
    required this.clickOpens,
  });

  final PeriodGradesEntity data;
  final List<StudentPeriodGrade> students;
  final int? selectedStudentId;
  final ValueChanged<StudentPeriodGrade> onSelect;
  final ValueChanged<StudentPeriodGrade> onOpen;

  /// Without a preview beside the table, a click opens the student.
  final bool clickOpens;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (students.isEmpty) return KeyEventResult.ignored;
    final index = students.indexWhere((s) => s.studentId == selectedStudentId);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      onSelect(students[(index + 1).clamp(0, students.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      onSelect(students[(index - 1).clamp(0, students.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && index >= 0) {
      onOpen(students[index]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = data.students.first.categories;

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
              _HeaderRow(categories: categories),
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
                      scale: data.scale,
                      selected: student.studentId == selectedStudentId,
                      onTap: () {
                        Focus.of(context).requestFocus();
                        clickOpens ? onOpen(student) : onSelect(student);
                      },
                      onDoubleTap: () => onOpen(student),
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
  const _HeaderRow({required this.categories});

  final List<CategoryGrade> categories;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: _flexStudent,
            child: Text('ESTUDIANTE', style: style),
          ),
          for (final c in categories)
            Expanded(
              flex: _flexCategory,
              child: Text(
                '${categoryLabel(c.categoryName).toUpperCase()} ${compactNumber(c.weight)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          Expanded(
            flex: _flexFinal,
            child: Text('NOTA FINAL', style: style),
          ),
          SizedBox(
            width: _statusWidth,
            child: Text('ESTADO', style: style),
          ),
          const SizedBox(width: _chevronWidth),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.student,
    required this.scale,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final StudentPeriodGrade student;
  final GradingScaleEntity scale;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final scale = widget.scale;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tint =
        AppColors.accents[student.studentId % AppColors.accents.length];
    final grade = student.periodGrade;
    final tabular = const [FontFeature.tabularFigures()];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: widget.selected
            ? AppColors.accentBlue.withValues(alpha: 0.07)
            : _hovering
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
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
                        radius: 17,
                        backgroundColor: tint.withValues(alpha: 0.12),
                        child: Text(
                          initialsOf(student.studentName),
                          style: textTheme.labelMedium?.copyWith(
                            color: tint,
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
                              student.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              student.studentCode,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final c in student.categories)
                  Expanded(
                    flex: _flexCategory,
                    child: Text(
                      c.gradeOnScale == null
                          ? '—'
                          : c.gradeOnScale!.toStringAsFixed(2),
                      style: textTheme.bodyMedium?.copyWith(
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                Expanded(
                  flex: _flexFinal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          grade == null ? '—' : grade.toStringAsFixed(2),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: tabular,
                          ),
                        ),
                      ),
                      if (grade != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: scaleFraction(grade, scale),
                                minHeight: 6,
                                color: AppColors.accentBlue,
                                backgroundColor: AppColors.accentBlue
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _statusWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: GradeStatusChip(
                        passing: student.passing,
                        hasGrade: grade != null,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _chevronWidth,
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurface.withValues(
                      alpha: _hovering || widget.selected ? 0.6 : 0.3,
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
