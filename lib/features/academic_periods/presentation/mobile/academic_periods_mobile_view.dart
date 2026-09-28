import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/app_status_chip.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';
import '../shared/academic_period_actions.dart';
import '../shared/academic_period_form.dart';

class AcademicPeriodsMobileView extends StatelessWidget {
  const AcademicPeriodsMobileView({super.key});

  Future<void> _openForm(
    BuildContext context, {
    AcademicPeriodEntity? initial,
  }) async {
    final data = await showMobileForm<AcademicPeriodFormResult>(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const MobilePageHeader(title: 'Periodos académicos'),
          Expanded(child: _buildBody(context, state)),
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
        return MobileCardList<AcademicPeriodEntity>(
          items: state.items,
          footer: AppPagination(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPageChanged: (page) =>
                context.read<AcademicPeriodsProvider>().load(page: page),
          ),
          itemBuilder: (context, item) => AppListTile(
            icon: Icons.calendar_month_outlined,
            title: item.name,
            subtitle:
                '${Formatters.date(item.startDate)} — ${Formatters.date(item.endDate)}',
            trailing: item.isActive
                ? const AppStatusChip(
                    label: 'Activo',
                    kind: AppStatusKind.success,
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () =>
                        AcademicPeriodActions.delete(context, item),
                  ),
            onTap: () => _openForm(context, initial: item),
          ),
        );
    }
  }
}
