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
import '../../shared/dashboard_error_notice.dart';

/// "Actividad reciente" as a vertical timeline (icons joined by a line).
class ActivityRail extends StatelessWidget {
  const ActivityRail({super.key});

  static const _maxItems = 6;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().recent;

    return DesktopSectionCard(
      icon: Icons.history_rounded,
      title: 'Actividad reciente',
      linkLabel: 'Ver todas',
      onLink: () => context.go(RoutePaths.audit),
      child: switch (state.status) {
        ViewStatus.error => DashboardErrorNotice(
          onRetry: () => context.read<AuditProvider>().refreshFeed(
            AuditProvider.recentQuery,
          ),
        ),
        ViewStatus.success => Column(
          children: [
            for (final (i, log) in state.items.take(_maxItems).indexed)
              _ActivityItem(
                log: log,
                isLast: i == state.items.take(_maxItems).length - 1,
              ),
          ],
        ),
        ViewStatus.initial || ViewStatus.loading => const SkeletonTileList(
          count: 4,
          leading: SkeletonLeading.circle,
        ),
        _ => Text(
          'Sin actividad reciente.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.log, required this.isLast});

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
                size: 40,
                circle: true,
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colors.outline)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    auditActionLabel(log.action),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(auditEntityLabel(log), style: textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.relativeTime(log.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
