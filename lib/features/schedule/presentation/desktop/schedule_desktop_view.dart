import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/desktop/desktop_catalog_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../providers/schedule_provider.dart';
import '../shared/schedule_week.dart';
import 'widgets/schedule_side_panel.dart';
import 'widgets/week_time_grid.dart';

/// Desktop: the week as an hour-by-hour calendar, with the selected day's
/// agenda and the week's totals beside it. ←/→ move a week, T goes to
/// today.
class ScheduleDesktopView extends StatelessWidget {
  const ScheduleDesktopView({super.key, required this.week});

  final ScheduleWeek week;

  static const _sideWidth = 330.0;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: week.selectedDay,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Ir a una fecha',
    );
    if (picked != null) week.onSelectDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScheduleProvider>().calendar;
    final range = state.status == DetailStatus.success ? state.data : null;
    final classCount = range?.days.fold(0, (n, d) => n + d.classes.length);
    final selected = range?.days
        .where((d) => isSameDay(d.date, week.selectedDay))
        .firstOrNull;
    final viewingToday =
        week.isCurrent && isSameDay(week.selectedDay, DateTime.now());

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): week.onPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowRight): week.onNext,
        const SingleActivator(LogicalKeyboardKey.keyT): week.onToday,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopCatalogHeader(
                  title: 'Horario',
                  subtitle: [
                    if (week.relativeName != null) week.relativeName!,
                    week.label,
                    if (classCount != null)
                      classCount == 1 ? '1 clase' : '$classCount clases',
                  ].join(' · '),
                  actions: [
                    _WeekNavigator(week: week, viewingToday: viewingToday),
                    AppButton(
                      label: 'Ir a una fecha',
                      icon: Icons.edit_calendar_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _pickDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: switch (state.status) {
                    DetailStatus.error => AppErrorState(
                      exception: state.error!,
                      onRetry: week.onRetry,
                    ),
                    DetailStatus.success => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: WeekTimeGrid(week: week, range: range!),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: _sideWidth,
                          child: ListView(
                            children: [
                              if (selected != null) ...[
                                DayAgendaCard(day: selected),
                                const SizedBox(height: 16),
                              ],
                              WeekSummaryCard(range: range),
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
    );
  }
}

/// ‹ Hoy › as one segmented control.
class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({required this.week, required this.viewingToday});

  final ScheduleWeek week;
  final bool viewingToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = SizedBox(
      height: 22,
      child: VerticalDivider(width: 1, color: colors.outline),
    );

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Semana anterior (←)',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            onPressed: week.onPrevious,
          ),
          divider,
          TextButton(
            onPressed: viewingToday ? null : week.onToday,
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Hoy'),
          ),
          divider,
          IconButton(
            tooltip: 'Semana siguiente (→)',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            onPressed: week.onNext,
          ),
        ],
      ),
    );
  }
}
