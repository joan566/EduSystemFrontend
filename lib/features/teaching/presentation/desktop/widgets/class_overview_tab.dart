import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../../audit/domain/entities/audit_log_entity.dart';
import '../../../../audit/presentation/providers/audit_provider.dart';
import '../../../../audit/presentation/shared/audit_labels.dart';
import '../../shared/class_evaluations.dart';
import 'class_evaluation_lists.dart';

/// "Resumen": latest evaluations beside the class's recent activity.
class ClassOverviewTab extends StatelessWidget {
  const ClassOverviewTab({
    super.key,
    required this.teachingPeriodId,
    required this.onShowEvaluations,
  });

  final int teachingPeriodId;

  /// Switches to the "Evaluaciones" tab.
  final VoidCallback onShowEvaluations;

  @override
  Widget build(BuildContext context) {
    final evaluations = _RecentEvaluations(
      teachingPeriodId: teachingPeriodId,
      onShowAll: onShowEvaluations,
    );
    final activity = _RecentActivity(teachingPeriodId: teachingPeriodId);

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: evaluations),
                const SizedBox(width: 20),
                Expanded(child: activity),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [evaluations, const SizedBox(height: 20), activity],
            ),
    );
  }
}

class _RecentEvaluations extends StatelessWidget {
  const _RecentEvaluations({
    required this.teachingPeriodId,
    required this.onShowAll,
  });

  final int teachingPeriodId;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final result = watchClassEvaluations(context, teachingPeriodId);
    final items = result.items;
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Evaluaciones recientes',
      linkLabel: 'Ver todas',
      onLink: onShowAll,
      child: result.failed
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    'No pudimos cargar las evaluaciones.',
                    style: textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: result.retry,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          : items == null
          ? const SkeletonTileList(
              count: 4,
              leadingSize: 36,
              trailingWidth: 64,
              spacing: 16,
            )
          : items.isEmpty
          ? Text(
              'Aún no hay exámenes ni actividades en esta clase.',
              style: textTheme.bodySmall,
            )
          : Column(
              children: [
                for (final (i, item) in items.take(6).indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  DesktopHoverTile(
                    onTap: () => context.push(item.route),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        TintedIcon(
                          icon: item.kind == ClassEvaluationKind.exam
                              ? Icons.fact_check_outlined
                              : Icons.assignment_outlined,
                          color: item.kind == ClassEvaluationKind.exam
                              ? AppColors.accentBlue
                              : AppColors.accentPurple,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.kindLabel} · ${item.detail}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (item.date != null)
                          Text(
                            Formatters.shortDayMonth(item.date!),
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.teachingPeriodId});

  final int teachingPeriodId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().classLogs(teachingPeriodId);
    final textTheme = Theme.of(context).textTheme;

    return DesktopSectionCard(
      icon: Icons.history_rounded,
      title: 'Actividad reciente',
      linkLabel: 'Ver todo',
      onLink: () => context.push(RoutePaths.auditForClass(teachingPeriodId)),
      child: switch (state.status) {
        ViewStatus.success => Column(
          children: [
            for (final (i, log) in state.items.indexed)
              _TimelineItem(log: log, isLast: i == state.items.length - 1),
          ],
        ),
        ViewStatus.empty => Text(
          'Aún no hay actividad en esta clase.',
          style: textTheme.bodySmall,
        ),
        ViewStatus.error => Row(
          children: [
            Expanded(
              child: Text(
                'No pudimos cargar la actividad.',
                style: textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => context.read<AuditProvider>().refreshClassLogs(
                teachingPeriodId,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        _ => const SkeletonTileList(
          leading: SkeletonLeading.circle,
          leadingSize: 28,
        ),
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.log, required this.isLast});

  final AuditLogEntity log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final color = log.isSuccess
        ? auditActionAccent(log.action)
        : AppColors.error;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              TintedIcon(
                icon: log.isSuccess
                    ? auditActionIcon(log.action)
                    : Icons.error_outline,
                color: color,
                size: 38,
                circle: true,
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colors.outline)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auditActionLabel(log.action),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(auditEntityLabel(log), style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
          Text(
            Formatters.relativeTime(log.createdAt),
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
