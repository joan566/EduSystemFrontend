import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_catalog_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_search_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_day_controller.dart';
import '../shared/attendance_visuals.dart';
import 'widgets/attendance_class_card.dart';
import 'widgets/student_attendance_sheet.dart';

/// Mobile: one class on one date. The roster shows each student's status;
/// tapping a student opens a sheet to set it, and the bottom button saves
/// everything marked.
class AttendanceMobileView extends StatelessWidget {
  const AttendanceMobileView({
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

  Future<void> _pickDate(BuildContext context) async {
    final period = this.period;
    if (period == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: period.startDate,
      lastDate: period.endDate,
      helpText: 'Fecha de la asistencia',
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickClass(BuildContext context) async {
    final picked = await showClassPickerSheet(context, selected: period);
    if (picked != null) onPeriodChanged(picked);
  }

  /// Room of the class's block on this weekday, if any.
  String? _room(BuildContext context) {
    final period = this.period;
    if (period == null) return null;
    return context
        .watch<ScheduleProvider>()
        .classSchedules(period.id)
        .items
        .where((b) => b.dayOfWeek == date.weekday && b.room != null)
        .firstOrNull
        ?.room;
  }

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    final state = period == null
        ? const DetailViewState<AttendanceDayEntity>()
        : context.watch<AttendanceProvider>().day(period.id, date);
    final room = _room(context);
    final loaded = state.status == DetailStatus.success && period != null;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        body: Column(
          children: [
            MobileCatalogHeader(
              title: 'Asistencia',
              subtitle: 'Registra la asistencia de tus clases',
              onAdd: period == null ? null : () => _pickDate(context),
              addIcon: Icons.calendar_month_outlined,
              addTooltip: 'Cambiar fecha',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  AttendanceClassCard(
                    period: period,
                    room: room,
                    teacherName: context.watch<AuthProvider>().user?.fullName,
                    onTap: () => _pickClass(context),
                  ),
                  if (period != null) ...[
                    const SizedBox(height: 12),
                    _DateCard(
                      date: date,
                      present: loaded ? controller.presentCount : null,
                      total: loaded ? controller.students.length : null,
                      onTap: () => _pickDate(context),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...switch (state.status) {
                    _ when period == null => [
                      const AppEmptyState(
                        title: 'Selecciona una clase',
                        message: 'Elige la clase para registrar su asistencia.',
                        icon: Icons.checklist_outlined,
                      ),
                    ],
                    DetailStatus.error => [
                      SizedBox(
                        height: 320,
                        child: AppErrorState(
                          exception: state.error!,
                          onRetry: onRetry,
                        ),
                      ),
                    ],
                    DetailStatus.success when controller.students.isEmpty => [
                      const AppEmptyState(
                        title: 'Sin estudiantes',
                        message: 'Esta clase no tiene estudiantes activos.',
                        icon: Icons.group_off_outlined,
                      ),
                    ],
                    DetailStatus.success => [
                      _SearchCard(controller: controller),
                      const SizedBox(height: 12),
                      _Roster(
                        controller: controller,
                        detail: [period.courseLabel, ?room].join('  ·  '),
                      ),
                    ],
                    _ => [const SizedBox(height: 240, child: AppLoading())],
                  },
                ],
              ),
            ),
            if (loaded && controller.students.isNotEmpty)
              _SaveBar(
                controller: controller,
                saved: state.data?.session != null,
              ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.present,
    required this.total,
    required this.onTap,
  });

  final DateTime date;
  final int? present;
  final int? total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: colors.onSurface),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '${Formatters.longDayMonth(date)} de ${date.year}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (present != null && total != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$present / $total',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        present == 1 ? 'presente' : 'presentes',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.controller});

  final AttendanceDayController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unmarked = controller.unmarkedCount;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(
            hint: 'Buscar estudiante...',
            initialValue: controller.query,
            onChanged: controller.search,
          ),
          if (unmarked > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unmarked == 1 ? '1 sin marcar' : '$unmarked sin marcar',
                      style: textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.saving
                        ? null
                        : controller.markUnmarkedPresent,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Marcar presentes'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.controller, required this.detail});

  final AttendanceDayController controller;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final students = controller.visibleStudents;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: students.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ningún estudiante coincide con la búsqueda.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            )
          : Column(
              children: [
                for (final (i, s) in students.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.outline,
                    ),
                  _StudentRow(
                    student: s,
                    status: controller.statusOf(s.studentId),
                    pending: controller.isPending(s.studentId),
                    hasObservation:
                        controller.observationOf(s.studentId) != null,
                    onTap: () => showStudentAttendanceSheet(
                      context,
                      controller: controller,
                      student: s,
                      detail: detail,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.status,
    required this.pending,
    required this.hasObservation,
    required this.onTap,
  });

  final SessionStudentRecord student;
  final AttendanceStatus? status;

  /// Marked here but not saved yet.
  final bool pending;
  final bool hasObservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.accentBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pending || hasObservation)
                    Text(
                      [
                        if (pending) 'Sin guardar',
                        if (hasObservation) 'Con observación',
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: pending ? AppColors.warning : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AttendanceStatusPill(status: status),
            IconButton(
              tooltip: 'Opciones de asistencia',
              icon: const Icon(Icons.more_vert),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.controller, required this.saved});

  final AttendanceDayController controller;

  /// The day already has a session on the server.
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final upToDate = saved && !controller.hasPending;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AppButton(
          label: upToDate ? 'Asistencia guardada' : 'Guardar asistencia',
          icon: upToDate ? Icons.check : Icons.how_to_reg_outlined,
          expand: true,
          isLoading: controller.saving,
          onPressed: controller.hasPending
              ? () => controller.save(context)
              : null,
        ),
      ),
    );
  }
}
