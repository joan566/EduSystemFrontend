import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_button.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';
import '../shared/academic_period_actions.dart';
import '../shared/academic_period_form.dart';

class AcademicPeriodsDesktopView extends StatelessWidget {
  const AcademicPeriodsDesktopView({super.key});

  Future<void> _openForm(
    BuildContext context, {
    AcademicPeriodEntity? initial,
  }) async {
    final data = await showDesktopDialog<AcademicPeriodFormResult>(
      context,
      child: AcademicPeriodForm(initial: initial),
    );
    if (data == null || !context.mounted) return;
    await AcademicPeriodActions.save(context, initial: initial, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicPeriodsProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: 'Periodos académicos',
            subtitle:
                'Periodos usados para organizar la enseñanza y la calificación.',
            actions: [
              AppButton(
                label: 'Nuevo periodo',
                icon: Icons.add,
                onPressed: () => _openForm(context),
              ),
            ],
          ),
          Expanded(child: _buildBody(context, state)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) =>
                  context.read<AcademicPeriodsProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<AcademicPeriodEntity> state,
  ) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AcademicPeriodsProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay periodos registrados',
          message:
              'Crea un periodo académico para empezar a asignar tus clases.',
          icon: Icons.calendar_month_outlined,
          actionLabel: 'Nuevo periodo',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return DesktopDataTable<AcademicPeriodEntity>(
          items: state.items,
          onRowTap: (item) => _openForm(context, initial: item),
          columns: [
            DesktopDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            DesktopDataColumn(
              label: 'Inicio',
              cellBuilder: (item) => Text(Formatters.date(item.startDate)),
            ),
            DesktopDataColumn(
              label: 'Fin',
              cellBuilder: (item) => Text(Formatters.date(item.endDate)),
            ),
            DesktopDataColumn(
              label: 'Estado',
              cellBuilder: (item) => item.isActive
                  ? const AppStatusChip(
                      label: 'Activo',
                      kind: AppStatusKind.success,
                    )
                  : const AppStatusChip(
                      label: 'Inactivo',
                      kind: AppStatusKind.neutral,
                    ),
            ),
            DesktopDataColumn(
              label: 'Acciones',
              // An active period can't be deleted, only edited.
              cellBuilder: (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openForm(context, initial: item),
                  ),
                  if (!item.isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () =>
                          AcademicPeriodActions.delete(context, item),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
