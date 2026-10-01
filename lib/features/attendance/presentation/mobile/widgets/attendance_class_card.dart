import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';

/// The class being marked; tapping it opens the class picker.
class AttendanceClassCard extends StatelessWidget {
  const AttendanceClassCard({
    super.key,
    required this.period,
    required this.room,
    required this.teacherName,
    required this.onTap,
  });

  final TeachingPeriodEntity? period;

  /// Room of the class's block on the selected weekday, if it has one.
  final String? room;
  final String? teacherName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final period = this.period;
    final muted = textTheme.bodySmall?.color;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              TintedIcon(
                icon: period == null
                    ? Icons.class_outlined
                    : subjectIcon(period.subjectName),
                color: period == null
                    ? AppColors.accentBlue
                    : subjectAccent(period.subjectId),
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clase', style: textTheme.bodySmall),
                    Text(
                      period == null ? 'Selecciona una clase' : period.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (period != null && (room != null || teacherName != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            if (room != null) ...[
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 3),
                              Text(room!, style: textTheme.bodySmall),
                              if (teacherName != null)
                                Text('  ·  ', style: textTheme.bodySmall),
                            ],
                            if (teacherName != null) ...[
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Prof. $teacherName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
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
