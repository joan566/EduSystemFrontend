import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/widgets/teaching_period_selector.dart';
import '../../domain/entities/attendance_entity.dart';
import '../providers/attendance_provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  TeachingPeriodEntity? _period;

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    setState(() => _period = period);
    if (period != null)
      context.read<AttendanceProvider>().load(teachingPeriodId: period.id);
  }

  Future<void> _createSession() async {
    if (_period == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date == null || !mounted) return;
    final session = await context.read<AttendanceProvider>().create(
      teachingPeriodId: _period!.id,
      sessionDate: date,
    );
    if (!mounted) return;
    if (session == null) {
      final error = context.read<AttendanceProvider>().lastError;
      if (error != null) context.showApiError(error);
    } else {
      context.push(RoutePaths.attendanceSessionDetail(session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttendanceProvider>().state;

    return Scaffold(
      floatingActionButton: context.isMobile && _period != null
          ? FloatingActionButton(
              onPressed: _createSession,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Asistencia',
            subtitle: 'Registra la asistencia de tus clases por fecha.',
            actions: context.isMobile || _period == null
                ? []
                : [
                    AppButton(
                      label: 'Nueva sesión',
                      icon: Icons.add,
                      onPressed: _createSession,
                    ),
                  ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TeachingPeriodSelector(
              value: _period,
              onChanged: _onPeriodChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _period == null
                ? const SizedBox.shrink()
                : _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<AttendanceSessionEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AttendanceProvider>().load(
            teachingPeriodId: _period!.id,
          ),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay sesiones registradas',
          message: 'Crea una sesión de asistencia para la fecha de hoy.',
          icon: Icons.checklist_outlined,
          actionLabel: 'Nueva sesión',
          onAction: _createSession,
        );
      case ViewStatus.success:
        return AppDataTable<AttendanceSessionEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) =>
              context.push(RoutePaths.attendanceSessionDetail(item.id)),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.checklist_outlined,
            title: item.name ?? Formatters.date(item.sessionDate),
            subtitle: Formatters.date(item.sessionDate),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () =>
                context.push(RoutePaths.attendanceSessionDetail(item.id)),
          ),
          columns: [
            AppDataColumn(
              label: 'Fecha',
              cellBuilder: (item) => Text(Formatters.date(item.sessionDate)),
            ),
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name ?? '—'),
            ),
          ],
        );
    }
  }
}
