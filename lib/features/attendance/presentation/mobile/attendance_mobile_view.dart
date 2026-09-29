import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/shared/teaching_period_selector.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_actions.dart';

class AttendanceMobileView extends StatelessWidget {
  const AttendanceMobileView({
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
      floatingActionButton: period == null
          ? null
          : FloatingActionButton(
              onPressed: () => AttendanceActions.createSession(
                context,
                teachingPeriodId: period.id,
              ),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Asistencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        return MobileCardList<AttendanceSessionEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) => context.read<AttendanceProvider>().load(
              teachingPeriodId: period.id,
              page: page,
            ),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.checklist_outlined,
            title: item.name ?? Formatters.date(item.sessionDate),
            subtitle: Formatters.date(item.sessionDate),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () =>
                context.push(RoutePaths.attendanceSessionDetail(item.id)),
          ),
        );
    }
  }
}
