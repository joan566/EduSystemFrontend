import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/gradebook_entities.dart';
import '../../shared/category_visuals.dart';
import '../../shared/grade_labels.dart';

const _flexEvaluation = 5;
const _flexComponent = 2;
const _flexWeight = 1;
const _flexGrade = 3;
const _flexContribution = 1;
const _flagsWidth = 72.0;

/// A student's evaluations in one table: component, weight in the final
/// grade, the grade and the points it adds; filterable by component.
/// A row opens the grade detail.
class GradeEntriesTable extends StatefulWidget {
  const GradeEntriesTable({super.key, required this.report});

  final StudentGradeReport report;

  @override
  State<GradeEntriesTable> createState() => _GradeEntriesTableState();
}

class _GradeEntriesTableState extends State<GradeEntriesTable> {
  int? _category;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categories = <int, String>{
      for (final e in report.evaluations) e.categoryId: e.categoryName,
    };
    final entries = report.evaluations
        .where((e) => _category == null || e.categoryId == _category)
        .toList();
    final header = textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    Widget head(String text, int flex, {TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(text.toUpperCase(), textAlign: align, style: header),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Actividades y evaluaciones', style: textTheme.titleMedium),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Todas (${report.evaluations.length})'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final c in categories.entries)
                    ChoiceChip(
                      avatar: Icon(categoryVisuals(c.value).icon, size: 16),
                      label: Text(categoryLabel(c.value)),
                      selected: _category == c.key,
                      onSelected: (_) => setState(() => _category = c.key),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
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
                padding: const EdgeInsets.fromLTRB(20, 12, 44, 12),
                child: Row(
                  children: [
                    head('Evaluación', _flexEvaluation),
                    head('Componente', _flexComponent),
                    head('Peso', _flexWeight),
                    head('Nota', _flexGrade),
                    head('Aporte', _flexContribution, align: TextAlign.end),
                    const SizedBox(width: _flagsWidth),
                  ],
                ),
              ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    title: 'Sin evaluaciones',
                    message:
                        'Esta clase aún no tiene evaluaciones en este componente.',
                    icon: Icons.assignment_outlined,
                  ),
                ),
              for (final entry in entries) ...[
                Divider(height: 1, color: colors.outline),
                _Row(
                  entry: entry,
                  onTap: () => context.push(
                    RoutePaths.gradeDetail(
                      report.teachingPeriodId,
                      report.student.id,
                      entry.evaluationId,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.entry, required this.onTap});

  final GradebookEntry entry;
  final VoidCallback onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visuals = categoryVisuals(e.categoryName);
    final date = e.evaluationDate;
    final fraction = e.fraction;
    final muted = e.excluded || e.earned == null;

    Widget flag(bool on, IconData icon, String label) => on
        ? Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Tooltip(
              message: label,
              child: Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
                semanticLabel: label,
              ),
            ),
          )
        : const SizedBox.shrink();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  flex: _flexEvaluation,
                  child: Row(
                    children: [
                      TintedIcon(
                        icon: evaluationIcon(e.type),
                        color: visuals.color,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              [
                                evaluationKindLabel(e),
                                if (date != null) Formatters.date(date),
                              ].join('  ·  '),
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
                Expanded(
                  flex: _flexComponent,
                  child: Text(visuals.label, style: textTheme.bodySmall),
                ),
                Expanded(
                  flex: _flexWeight,
                  child: Text(
                    weightLabel(e.weight),
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: _flexGrade,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          entryGradeLabel(e),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: muted ? AppColors.textSecondary : null,
                          ),
                        ),
                      ),
                      if (fraction != null && !e.excluded)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: fraction.clamp(0.0, 1.0),
                                minHeight: 5,
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
                Expanded(
                  flex: _flexContribution,
                  child: Text(
                    contributionLabel(e) ?? '—',
                    textAlign: TextAlign.end,
                    style: textTheme.bodySmall,
                  ),
                ),
                SizedBox(
                  width: _flagsWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      flag(e.hasRubric, Icons.rule, 'Con rúbrica'),
                      flag(e.hasAttachment, Icons.attach_file, 'Con archivo'),
                      flag(
                        e.comment != null,
                        Icons.chat_bubble_outline,
                        'Con comentario',
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.onSurface.withValues(
                    alpha: _hovering ? 0.6 : 0.3,
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
