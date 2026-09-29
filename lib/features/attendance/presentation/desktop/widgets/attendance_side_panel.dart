import 'package:flutter/material.dart';

import '../../../../../core/state/list_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/desktop/desktop_section_card.dart';
import '../../../../../core/widgets/shared/app_button.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../shared/attendance_day_controller.dart';
import '../../shared/attendance_visuals.dart';

/// Pending changes and the one button that sends them all (Ctrl+S).
class AttendanceSaveCard extends StatelessWidget {
  const AttendanceSaveCard({
    super.key,
    required this.controller,
    required this.hasSession,
  });

  final AttendanceDayController controller;

  /// The day already has a session on the server.
  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pending = controller.pendingCount;
    final (icon, color, title, message) = pending > 0
        ? (
            Icons.edit_outlined,
            AppColors.warning,
            pending == 1
                ? '1 cambio sin guardar'
                : '$pending cambios sin guardar',
            'Se envían todos juntos al guardar.',
          )
        : hasSession
        ? (
            Icons.cloud_done_outlined,
            AppColors.success,
            'Asistencia guardada',
            'No hay cambios pendientes.',
          )
        : (
            Icons.info_outline,
            AppColors.accentBlue,
            'Sin registro para este día',
            'Marca a los estudiantes y guarda para crearlo.',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pending > 0 ? color.withValues(alpha: 0.5) : colors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(message, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Tooltip(
            message: 'Ctrl + S',
            child: AppButton(
              label: 'Guardar asistencia',
              icon: Icons.how_to_reg_outlined,
              expand: true,
              isLoading: controller.saving,
              onPressed: pending > 0 ? () => controller.save(context) : null,
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: controller.saving ? null : controller.discard,
              child: const Text('Descartar cambios'),
            ),
          ],
        ],
      ),
    );
  }
}

/// How the day splits between statuses: a stacked bar and a legend with
/// counts.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.controller});

  final AttendanceDayController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = controller.students.length;
    final present = controller.presentCount;
    final unmarked = controller.unmarkedCount;
    final segments = [
      for (final status in AttendanceStatus.values)
        (
          label: attendanceVisuals(status).label,
          color: attendanceVisuals(status).color,
          count: controller.countOf(status),
        ),
      (label: 'Sin marcar', color: colors.outline, count: unmarked),
    ];

    return DesktopSectionCard(
      icon: Icons.donut_small_outlined,
      title: 'Resumen del día',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$present',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ $total presentes',
                  style: textTheme.bodyMedium?.copyWith(
                    color: textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const Spacer(),
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    Formatters.percentage(present / total * 100),
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? ColoredBox(color: colors.surfaceContainerHighest)
                  : Row(
                      children: [
                        for (final s in segments.where((s) => s.count > 0))
                          Expanded(
                            flex: s.count,
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: s.color,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          for (final s in segments)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.label, style: textTheme.bodyMedium)),
                  Text(
                    '${s.count}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The class's latest attendance days; clicking one opens it.
class RecentSessionsCard extends StatelessWidget {
  const RecentSessionsCard({
    super.key,
    required this.state,
    required this.date,
    required this.onOpen,
  });

  final ListViewState<AttendanceSessionEntity> state;
  final DateTime date;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // One entry per date (older data may have two sessions on a day).
    final seen = <DateTime>{};
    final sessions = state.items
        .where((s) => seen.add(DateUtils.dateOnly(s.sessionDate)))
        .take(8)
        .toList();

    return DesktopSectionCard(
      icon: Icons.history,
      title: 'Registros recientes',
      child: switch (state.status) {
        ViewStatus.initial || ViewStatus.loading => const Padding(
          padding: EdgeInsets.all(8),
          child: LinearProgressIndicator(),
        ),
        ViewStatus.error => Text(
          'No se pudieron cargar los registros.',
          style: textTheme.bodySmall,
        ),
        _ when sessions.isEmpty => Text(
          'Aún no hay asistencia registrada en esta clase.',
          style: textTheme.bodySmall,
        ),
        _ => Column(
          children: [
            for (final s in sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SessionTile(
                  session: s,
                  current: DateUtils.isSameDay(s.sessionDate, date),
                  onTap: () => onOpen(s.sessionDate),
                ),
              ),
          ],
        ),
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.current,
    required this.onTap,
  });

  final AttendanceSessionEntity session;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = session.sessionDate;
    return Material(
      color: current
          ? AppColors.accentBlue.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: current ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text(
                      '${d.day}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: current ? AppColors.accentBlue : null,
                      ),
                    ),
                    Text(
                      Formatters.shortMonth(d).toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Formatters.weekdayName(d.weekday),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: current ? FontWeight.w600 : null,
                  ),
                ),
              ),
              if (current)
                Text(
                  'Abierta',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.accentBlue,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: textTheme.bodySmall?.color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
