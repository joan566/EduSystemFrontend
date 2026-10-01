import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../academic_periods/domain/entities/academic_period_entity.dart';
import '../../shared/class_counts.dart';
import '../../shared/class_grouping.dart';

/// One course of the Clases list: its name and students, then a row per
/// subject the teacher teaches in it. Tapping a subject opens its class.
///
/// With [compact] (every listed class is of the same subject, named once
/// in the screen's header) the course itself is the only row.
class CourseClassesCard extends StatelessWidget {
  const CourseClassesCard({
    super.key,
    required this.course,
    required this.academicPeriod,
    required this.weeklySessions,
    required this.compact,
    required this.onOpen,
    required this.onCreateClass,
    required this.onActions,
    required this.onAddSubject,
  });

  final CourseClasses course;

  /// The period the list is about; null = all periods.
  final AcademicPeriodEntity? academicPeriod;

  /// Sessions in the coming week by class id; null while unknown.
  final Map<int, int>? weeklySessions;

  final bool compact;
  final ValueChanged<ClassEntry> onOpen;
  final ValueChanged<ClassEntry> onCreateClass;
  final ValueChanged<ClassEntry> onActions;
  final VoidCallback onAddSubject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final students = course.studentCount;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: compact
          ? _EntryRow(
              entry: course.entries.single,
              title: course.label,
              students: students,
              course: course,
              card: this,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: course.label,
                            style: textTheme.titleMedium,
                            children: [
                              if (students != null)
                                TextSpan(
                                  text:
                                      '  ·  $students '
                                      '${students == 1 ? 'estudiante' : 'estudiantes'}',
                                  style: textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar materia a ${course.label}',
                        icon: const Icon(Icons.add, size: 20),
                        color: AppColors.accentBlue,
                        onPressed: onAddSubject,
                      ),
                    ],
                  ),
                ),
                for (final (i, entry) in course.entries.indexed) ...[
                  Divider(
                    height: 1,
                    indent: i == 0 ? 0 : 66,
                    color: colors.outline,
                  ),
                  _EntryRow(
                    entry: entry,
                    title: entry.subjectName,
                    students: null,
                    course: course,
                    card: this,
                  ),
                ],
              ],
            ),
    );
  }
}

/// A subject (or, compact, the course) with its class in the period.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.title,
    required this.students,
    required this.course,
    required this.card,
  });

  final ClassEntry entry;
  final String title;

  /// Shown in the counts line (compact rows only).
  final int? students;
  final CourseClasses course;
  final CourseClassesCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final period = entry.period;
    final active = entry.assignment.active;
    final academicPeriod = card.academicPeriod;
    final weekly = period == null ? null : card.weeklySessions?[period.id];
    final students = this.students;

    final Widget detail;
    if (period == null) {
      detail = Text(
        academicPeriod == null
            ? 'Sin clases en ningún periodo'
            : 'Sin clase en ${academicPeriod.name}',
        style: textTheme.bodySmall?.copyWith(fontSize: 11),
      );
    } else if (students != null) {
      detail = ClassCounts(weeklySessions: weekly, students: students);
    } else {
      detail = Text(
        [
          if (academicPeriod == null) period.academicPeriodName,
          switch (weekly) {
            null => null,
            0 => 'Sin horario',
            1 => '1 clase/sem',
            final n => '$n clases/sem',
          },
        ].nonNulls.join('  ·  '),
        style: textTheme.bodySmall?.copyWith(fontSize: 11),
      );
    }

    return InkWell(
      onTap: period == null ? null : () => card.onOpen(entry),
      onLongPress: () => card.onActions(entry),
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            card.compact ? 14 : 10,
            8,
            card.compact ? 14 : 10,
          ),
          child: Row(
            children: [
              TintedIcon(
                icon: subjectIcon(entry.subjectName),
                color: subjectAccent(entry.subjectId),
                size: card.compact ? 48 : 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: card.compact
                          ? textTheme.titleMedium
                          : textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    detail,
                  ],
                ),
              ),
              if (!active) ...[
                const AppStatusChip(
                  label: 'Inactiva',
                  kind: AppStatusKind.neutral,
                ),
                const SizedBox(width: 4),
              ],
              if (period == null && academicPeriod != null && active)
                TextButton(
                  onPressed: () => card.onCreateClass(entry),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Crear'),
                )
              else if (period != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
