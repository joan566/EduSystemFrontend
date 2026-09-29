import 'package:flutter/material.dart';

import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../shared/class_counts.dart';

/// A class (or assignment) row card: tinted group badge in the subject's
/// color, "Materia — Curso", a secondary line, counts, a status chip.
class ClassListCard extends StatelessWidget {
  const ClassListCard({
    super.key,
    required this.title,
    required this.color,
    required this.status,
    required this.onTap,
    this.subtitle,
    this.weeklySessions,
    this.students,
    this.footnote,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final Widget status;

  /// Counts line; shown when [students] is known.
  final int? weeklySessions;
  final int? students;

  /// Shown instead of the counts (e.g. "Sin clase en 2026-2").
  final String? footnote;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final students = this.students;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              TintedIcon(icon: Icons.groups_rounded, color: color, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    if (students != null)
                      ClassCounts(
                        weeklySessions: weeklySessions,
                        students: students,
                      )
                    else if (footnote != null)
                      Text(
                        footnote!,
                        style: textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  status,
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
