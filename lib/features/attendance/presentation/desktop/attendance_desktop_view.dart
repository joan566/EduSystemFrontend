import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_actions.dart';

class AttendanceDesktopView extends StatelessWidget {
  const AttendanceDesktopView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    this.preferredPeriodId,
  });

  final TeachingPeriodEntity? period;
  final ValueChanged<TeachingPeriodEntity?> onPeriodChanged;

  /// Class the selector picks on first load, if present.
  final int? preferredPeriodId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceProvider>().state;
    final period = this.period;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Asistencia',
            subtitle: 'Registra la asistencia de tus clases por fecha.',
            actions: [
              if (period != null)
                AppButton(
                  label: 'Nueva sesión',
                  icon: Icons.add,
                  onPressed: () => AttendanceActions.createSession(
                    context,
                    teachingPeriodId: period.id,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TeachingPeriodSelector(
              preferredId: preferredPeriodId,
              value: period,
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: period == null
                ? const AppEmptyState(
                    title: 'Selecciona una clase',
                    message:
                        'Elige una clase arriba para ver sus sesiones de asistencia.',
                    icon: Icons.checklist_outlined,
                  )
                : _buildBody(context, state, period),
          ),
          if (period != null && state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) => context.read<AttendanceProvider>().load(
                teachingPeriodId: period.id,
                page: page,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<AttendanceSessionEntity> state,
    TeachingPeriodEntity period,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AttendanceProvider>().load(
            teachingPeriodId: period.id,
          ),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay sesiones registradas',
          message: 'Crea una sesión de asistencia para la fecha de hoy.',
          icon: Icons.checklist_outlined,
          actionLabel: 'Nueva sesión',
          onAction: () => AttendanceActions.createSession(
            context,
            teachingPeriodId: period.id,
          ),
        );
      case ViewStatus.success:
        return DesktopDataTable<AttendanceSessionEntity>(
          items: state.items,
          onRowTap: (item) =>
              context.push(RoutePaths.attendanceSessionDetail(item.id)),
          columns: [
            DesktopDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(Formatters.date(item.sessionDate)),
            ),
            DesktopDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name ?? '—'),
            ),
          ],
        );
    }
  }
}
