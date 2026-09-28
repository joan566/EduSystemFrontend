import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';
import '../../shared/dashboard_error_notice.dart';
import '../../../../../core/theme/subject_visuals.dart';
import 'mobile_dashboard_section.dart';

/// "Tus clases": the teacher's classes as a horizontal, swipeable row of
/// cards (subject, course, period, sessions this week, students).
class ClassesCarouselSection extends StatelessWidget {
  const ClassesCarouselSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodsState;
    // Null while the week hasn't loaded (or failed): the card then omits
    // the count instead of claiming zero sessions.
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;

    return MobileDashboardSection(
      icon: Icons.menu_book_outlined,
      title: 'Tus clases',
      linkLabel: 'Ver todas',
      onLink: () => context.go(RoutePaths.teaching),
      // The carousel runs to the card's right edge so it reads as
      // scrollable.
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 16),
      child: switch (state.status) {
        ViewStatus.error => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: DashboardErrorNotice(
            onRetry: () =>
                context.read<TeachingProvider>().loadPeriods(page: 0),
          ),
        ),
        ViewStatus.success => SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final period = state.items[index];
              return _ClassCard(
                period: period,
                weeklySessions: weekly == null ? null : weekly[period.id] ?? 0,
              );
            },
          ),
        ),
        _ => Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 4),
          child: Text(
            'Aún no tienes clases. Crea una asignación y vincúlala a un '
            'periodo académico.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.period, required this.weeklySessions});

  final TeachingPeriodEntity period;

  /// Sessions in the next 7 days; null when unknown.
  final int? weeklySessions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 236,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(RoutePaths.teachingPeriodDetail(period.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              children: [
                TintedIcon(
                  icon: subjectIcon(period.subjectName),
                  color: subjectAccent(period.subjectId),
                  size: 44,
                  solid: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        period.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${period.courseLabel} · ${period.academicPeriodName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      _Counts(
                        weeklySessions: weeklySessions,
                        students: period.studentCount,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.weeklySessions, required this.students});

  final int? weeklySessions;
  final int students;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);
    final iconColor = style?.color;

    Widget item(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: style),
      ],
    );

    final sessions = weeklySessions;
    return Wrap(
      spacing: 10,
      children: [
        if (sessions != null)
          item(
            Icons.event_outlined,
            sessions == 1 ? '1 clase/sem' : '$sessions clases/sem',
          ),
        item(
          Icons.people_alt_outlined,
          students == 1 ? '1 alumno' : '$students alumnos',
        ),
      ],
    );
  }
}
