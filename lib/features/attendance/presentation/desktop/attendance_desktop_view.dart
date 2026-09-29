import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_day_controller.dart';
import 'widgets/attendance_roster_table.dart';
import 'widgets/attendance_side_panel.dart';
import 'widgets/attendance_toolbar.dart';

/// Desktop: class and date on a toolbar, the roster as a marking table
/// (mouse or keyboard) and a side panel with the pending changes, the
/// day's summary and the class's recent attendance days. Every mark stays
/// local until "Guardar asistencia" (or Ctrl+S) sends them all at once.
class AttendanceDesktopView extends StatelessWidget {
  const AttendanceDesktopView({
    super.key,
    required this.period,
    required this.date,
    required this.controller,
    required this.onPeriodChanged,
    required this.onDateChanged,
    required this.onRetry,
  });

  final TeachingPeriodEntity? period;
  final DateTime date;
  final AttendanceDayController controller;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onRetry;

  static const _sideWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final state = provider.day;
    final period = this.period;
    final blocks = period == null
        ? const []
        : context.watch<ScheduleProvider>().classSchedules(period.id).items;
    final room = blocks
        .where((b) => b.dayOfWeek == date.weekday && b.room != null)
        .firstOrNull
        ?.room;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            if (controller.hasPending && !controller.saving) {
              controller.save(context);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DesktopCatalogHeader(
                    title: 'Asistencia',
                    subtitle: 'Registra la asistencia de tus clases',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AttendanceClassMenu(
                        period: period,
                        onChanged: onPeriodChanged,
                      ),
                      if (period != null)
                        AttendanceDateNavigator(
                          period: period,
                          date: date,
                          meetingDays: {for (final b in blocks) b.dayOfWeek},
                          room: room,
                          onChanged: onDateChanged,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: switch (state.status) {
                      _ when period == null => const AppEmptyState(
                        title: 'Selecciona una clase',
                        message: 'Elige la clase para registrar su asistencia.',
                        icon: Icons.checklist_outlined,
                      ),
                      DetailStatus.error => AppErrorState(
                        exception: state.error!,
                        onRetry: onRetry,
                      ),
                      DetailStatus.success when controller.students.isEmpty =>
                        const AppEmptyState(
                          title: 'Sin estudiantes',
                          message: 'Esta clase no tiene estudiantes activos.',
                          icon: Icons.group_off_outlined,
                        ),
                      DetailStatus.success => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AttendanceRosterTable(
                              controller: controller,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: _sideWidth,
                            child: ListView(
                              children: [
                                AttendanceSaveCard(
                                  controller: controller,
                                  hasSession: state.data?.session != null,
                                ),
                                const SizedBox(height: 16),
                                AttendanceSummaryCard(controller: controller),
                                const SizedBox(height: 16),
                                RecentSessionsCard(
                                  state: provider.state,
                                  date: date,
                                  onOpen: onDateChanged,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _ => const AppLoading(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
