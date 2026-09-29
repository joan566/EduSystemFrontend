import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/gradebook_entities.dart';
import '../../shared/category_visuals.dart';
import '../../shared/grade_labels.dart';

/// One evaluation in a student's grades: kind and date, its weight in the
/// final grade, the grade and the points it adds.
class GradeEntryCard extends StatelessWidget {
  const GradeEntryCard({super.key, required this.entry, required this.onTap});

  final GradebookEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visuals = categoryVisuals(entry.categoryName);
    final date = entry.evaluationDate;
    final contribution = contributionLabel(entry);
    final graded = entry.earned != null && !entry.excluded;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TintedIcon(
                icon: evaluationIcon(entry.type),
                color: visuals.color,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      [
                        evaluationKindLabel(entry),
                        if (date != null) Formatters.date(date),
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Peso: ${weightLabel(entry.weight)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ),
                        if (entry.hasRubric)
                          ..._flag(Icons.rule, 'Con rúbrica'),
                        if (entry.hasAttachment)
                          ..._flag(Icons.attach_file, 'Con archivo'),
                        if (entry.comment != null)
                          ..._flag(Icons.chat_bubble_outline, 'Con comentario'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 70),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: graded
                      ? AppColors.accentBlue.withValues(alpha: 0.06)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      entryGradeLabel(entry),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: graded
                            ? AppColors.accentBlue
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (contribution != null)
                      Text(
                        '($contribution)',
                        style: textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _flag(IconData icon, String label) => [
    const SizedBox(width: 8),
    Tooltip(
      message: label,
      child: Icon(
        icon,
        size: 13,
        color: AppColors.textSecondary,
        semanticLabel: label,
      ),
    ),
  ];
}
