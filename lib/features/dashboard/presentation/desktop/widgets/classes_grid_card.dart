import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/subject_visuals.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../../teaching/presentation/providers/teaching_provider.dart';
import '../../../../teaching/presentation/shared/class_counts.dart';
import '../../shared/dashboard_error_notice.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';

/// "Tus clases": a two-column grid of class cards.
class ClassesGridCard extends StatelessWidget {
  const ClassesGridCard({super.key});

  static const _maxCards = 6;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachingProvider>().periodsState;
    final weekly = context
        .watch<ScheduleProvider>()
        .week
        .data
        ?.occurrencesByTeachingPeriod;

    return DesktopSectionCard(
      icon: Icons.menu_book_outlined,
      title: 'Tus clases',
      linkLabel: 'Ver todas',
      onLink: () => context.go(RoutePaths.teaching),
      child: switch (state.status) {
        ViewStatus.error => DashboardErrorNotice(
          onRetry: () => context.read<TeachingProvider>().refreshPeriods(),
        ),
        ViewStatus.success => LayoutBuilder(
          // Two columns of equal width inside this card.
          builder: (context, constraints) {
            const gap = 12.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final period in state.items.take(_maxCards))
                  SizedBox(
                    width: width,
                    child: _ClassTile(
                      period: period,
                      weeklySessions: weekly == null
                          ? null
                          : weekly[period.id] ?? 0,
                    ),
                  ),
              ],
            );
          },
        ),
        _ => Text(
          'Aún no tienes clases. Crea una asignación y vincúlala a un '
          'periodo académico.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      },
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.period, required this.weeklySessions});

  final TeachingPeriodEntity period;
  final int? weeklySessions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return DesktopHoverTile(
      onTap: () => context.push(RoutePaths.teachingPeriodDetail(period.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIcon(
            icon: subjectIcon(period.subjectName),
            color: subjectAccent(period.subjectId),
            size: 42,
            solid: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${period.courseLabel} · ${period.academicPeriodName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClassCounts(
                  weeklySessions: weeklySessions,
                  students: period.studentCount,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: colors.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
