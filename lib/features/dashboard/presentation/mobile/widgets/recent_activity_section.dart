import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../audit/domain/entities/audit_log_entity.dart';
import '../../../../audit/presentation/providers/audit_provider.dart';
import '../../../../audit/presentation/shared/audit_labels.dart';
import '../../shared/dashboard_error_notice.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../shared/activity_visuals.dart';
import 'mobile_dashboard_section.dart';

/// Latest actions on the account (from the audit trail), newest first.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  static const _maxItems = 5;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().state;

    return MobileDashboardSection(
      icon: Icons.history_rounded,
      title: 'Actividad reciente',
      linkLabel: 'Ver todo',
      onLink: () => context.push(RoutePaths.audit),
      child: switch (state.status) {
        ViewStatus.error => DashboardErrorNotice(
          onRetry: () => context.read<AuditProvider>().load(page: 0),
        ),
        ViewStatus.success => Column(
          children: [
            for (final (i, log) in state.items.take(_maxItems).indexed) ...[
              if (i > 0) const Divider(height: 1),
              _ActivityRow(log: log),
            ],
          ],
        ),
        _ => Text(
          'Sin actividad reciente.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = log.isSuccess
        ? auditActionAccent(log.action)
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          TintedIcon(
            icon: log.isSuccess ? auditActionIcon(log.action) : Icons.error,
            color: color,
            size: 38,
            circle: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auditActionLabel(log.action),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  auditEntityLabel(log),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.relativeTime(log.createdAt),
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
