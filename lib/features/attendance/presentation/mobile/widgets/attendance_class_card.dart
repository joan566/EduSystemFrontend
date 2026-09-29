import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';

/// The class being marked; tapping it opens [showClassPickerSheet].
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
                      period == null
                          ? 'Selecciona una clase'
                          : '${period.subjectName} — ${period.courseLabel}',
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

/// Bottom sheet listing the teacher's classes; returns the one picked.
Future<TeachingPeriodEntity?> showClassPickerSheet(
  BuildContext context, {
  required TeachingPeriodEntity? selected,
}) {
  return showModalBottomSheet<TeachingPeriodEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final periods = context.watch<TeachingProvider>().allPeriods;
      final textTheme = Theme.of(context).textTheme;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Elegir clase', style: textTheme.titleLarge),
            ),
            Flexible(
              child: periods.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Todavía no tienes clases asignadas.',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      children: [
                        for (final p in periods)
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selected: p.id == selected?.id,
                            selectedTileColor: AppColors.accentBlue.withValues(
                              alpha: 0.08,
                            ),
                            leading: TintedIcon(
                              icon: subjectIcon(p.subjectName),
                              color: subjectAccent(p.subjectId),
                            ),
                            title: Text(
                              '${p.subjectName} — ${p.courseLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              '${p.academicPeriodName} · '
                              '${p.studentCount} estudiantes',
                              style: textTheme.bodySmall,
                            ),
                            trailing: p.id == selected?.id
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.accentBlue,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(p),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}
