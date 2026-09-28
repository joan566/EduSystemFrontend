import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/detail_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../schedule/domain/entities/schedule_entities.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import 'desktop_dashboard_card.dart';

/// The class in progress, or the next one today, with a "Ver clase" CTA.
/// Renders nothing until today's schedule has loaded successfully.
class NextClassCard extends StatelessWidget {
  const NextClassCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().today;
    if (state.status != DetailStatus.success) return const SizedBox.shrink();
    final today = state.data!;
    final next = today.nextClass;
    final inProgress =
        next != null && today.statusOf(next) == ScheduledClassStatus.inProgress;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return DesktopDashboardCard(
      icon: Icons.schedule_outlined,
      title: inProgress ? 'En curso' : 'Próxima clase',
      child: next == null
          ? Text(
              today.classes.isEmpty
                  ? 'Hoy no tienes clases programadas.'
                  : 'Terminaste tus clases de hoy.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TintedIcon(
                        icon: subjectIcon(next.subjectName),
                        color: subjectAccent(next.subjectId),
                        size: 46,
                        solid: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              next.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              [
                                next.courseLabel,
                                next.academicPeriodName,
                              ].join(' · '),
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatTimeRange(next.startTime, next.endTime),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (next.room != null)
                              Text(next.room!, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      RoutePaths.teachingPeriodDetail(next.teachingPeriodId),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Ver clase'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
