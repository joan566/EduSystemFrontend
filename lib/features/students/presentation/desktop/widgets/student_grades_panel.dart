import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_stat_card.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/app_loading.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/student_entity.dart';
import '../../shared/student_grades_controller.dart';

const _flexClass = 5;
const _flexGrade = 4;
const _flexCategories = 2;
const _actionsWidth = 88.0;

/// "Notas" on desktop: a KPI row, then one table row per class with the
/// period grade; a row expands to its per-category breakdown.
class StudentGradesPanel extends StatefulWidget {
  const StudentGradesPanel({
    super.key,
    required this.detail,
    required this.controller,
  });

  final StudentDetailEntity detail;
  final StudentGradesController controller;

  @override
  State<StudentGradesPanel> createState() => _StudentGradesPanelState();
}

class _StudentGradesPanelState extends State<StudentGradesPanel> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.ensureLoaded(widget.detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final grades = widget.controller.grades;
        if (grades == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: AppLoading(),
          );
        }
        if (grades.isEmpty) {
          return const AppEmptyState(
            title: 'Sin clases con este estudiante',
            message:
                'No dictas clases en los cursos en los que está o estuvo '
                'matriculado.',
            icon: Icons.menu_book_outlined,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Kpis(grades: grades),
            const SizedBox(height: 20),
            _table(context, grades),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.controller.loading
                    ? null
                    : () => widget.controller.reload(widget.detail),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar notas'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context, List<StudentClassGrade> grades) {
    final colors = Theme.of(context).colorScheme;
    final header = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    Widget head(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text.toUpperCase(), style: header),
    );

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                head('Clase', _flexClass),
                head('Nota del periodo', _flexGrade),
                head('Categorías', _flexCategories),
                const SizedBox(width: _actionsWidth),
              ],
            ),
          ),
          for (final grade in grades) ...[
            Divider(height: 1, color: colors.outline),
            _GradeRow(
              grade: grade,
              expanded: _expanded.contains(grade.period.id),
              onToggle: () => setState(() {
                if (!_expanded.remove(grade.period.id)) {
                  _expanded.add(grade.period.id);
                }
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.grades});

  final List<StudentClassGrade> grades;

  @override
  Widget build(BuildContext context) {
    final graded = grades
        .where((g) => g.grade?.periodGrade != null && g.scale != null)
        .toList();
    final pending = grades.where((g) => g.needsConfiguration).length;
    // An average only makes sense on one scale.
    final scales = {
      for (final g in graded)
        '${g.scale!.minimumValue}-${g.scale!.maximumValue}',
    };
    final average = graded.isNotEmpty && scales.length == 1
        ? graded.map((g) => g.grade!.periodGrade!).reduce((a, b) => a + b) /
              graded.length
        : null;

    final cards = [
      DesktopStatCard(
        label: 'Clases',
        value: '${grades.length}',
        icon: Icons.menu_book_outlined,
        accentColor: AppColors.accentBlue,
      ),
      DesktopStatCard(
        label: 'Con nota',
        value: '${graded.length} / ${grades.length}',
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.accentTeal,
      ),
      DesktopStatCard(
        label: scales.length > 1 ? 'Promedio (escalas distintas)' : 'Promedio',
        value: average == null
            ? '—'
            : Formatters.grade(
                average,
                graded.first.scale!.maximumValue,
                decimals: 1,
              ),
        icon: Icons.star_outline_rounded,
        accentColor: AppColors.accentPurple,
      ),
      DesktopStatCard(
        label: 'Sin configurar',
        value: '$pending',
        icon: Icons.tune,
        accentColor: AppColors.warning,
      ),
    ];

    return Row(
      children: [
        for (final (i, card) in cards.indexed) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: card),
        ],
      ],
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({
    required this.grade,
    required this.expanded,
    required this.onToggle,
  });

  final StudentClassGrade grade;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final period = grade.period;
    final scale = grade.scale;
    final value = grade.grade?.periodGrade;
    final categories = grade.grade?.categories ?? const [];
    final fraction = value != null && scale != null
        ? ((value - scale.minimumValue) /
                  (scale.maximumValue - scale.minimumValue))
              .clamp(0.0, 1.0)
        : null;
    final canExpand = categories.isNotEmpty;

    final Widget gradeCell;
    if (grade.needsConfiguration) {
      gradeCell = Text(
        'Falta configurar escala y pesos',
        style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
      );
    } else if (grade.error != null) {
      gradeCell = Text(
        'No se pudo cargar',
        style: textTheme.bodySmall?.copyWith(color: AppColors.error),
      );
    } else if (grade.grade == null) {
      gradeCell = Text('Sin notas en esta clase', style: textTheme.bodySmall);
    } else {
      gradeCell = Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              value == null || scale == null
                  ? 'Pendiente'
                  : Formatters.grade(value, scale.maximumValue, decimals: 1),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (fraction != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    color: AppColors.accentBlue,
                    backgroundColor: AppColors.accentBlue.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: canExpand ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  flex: _flexClass,
                  child: Row(
                    children: [
                      TintedIcon(
                        icon: subjectIcon(period.subjectName),
                        color: subjectAccent(period.subjectId),
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${period.courseLabel}  ·  '
                              '${period.academicPeriodName}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: _flexGrade, child: gradeCell),
                Expanded(
                  flex: _flexCategories,
                  child: Text(
                    canExpand ? '${categories.length}' : '—',
                    style: textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: _actionsWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Abrir calificaciones de la clase',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            context.push(RoutePaths.gradesForClass(period.id)),
                        icon: const Icon(Icons.open_in_new, size: 18),
                      ),
                      if (canExpand)
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        )
                      else
                        const SizedBox(width: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded && canExpand)
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
            padding: const EdgeInsets.fromLTRB(70, 8, 20, 14),
            child: Column(
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            c.categoryName,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Peso ${c.weight.toStringAsFixed(0)}%',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            c.evaluationCount == 1
                                ? '1 evaluación'
                                : '${c.evaluationCount} evaluaciones',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            c.achievement == null
                                ? '—'
                                : 'Logro ${Formatters.percentage(c.achievement!)}',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            c.gradeOnScale != null && scale != null
                                ? Formatters.grade(
                                    c.gradeOnScale!,
                                    scale.maximumValue,
                                    decimals: 1,
                                  )
                                : '—',
                            textAlign: TextAlign.end,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
