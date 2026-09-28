import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../providers/audit_provider.dart';
import '../shared/audit_labels.dart';

class AuditDesktopView extends StatelessWidget {
  const AuditDesktopView({
    super.key,
    required this.actionFilter,
    required this.onActionFilterChanged,
  });

  final AuditAction? actionFilter;
  final ValueChanged<AuditAction?> onActionFilterChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          const DesktopPageHeader(
            title: 'Auditoría',
            subtitle: 'Historial de acciones realizadas en tu cuenta.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 240,
                child: AppDropdown<AuditAction?>(
                  label: 'Filtrar por acción',
                  value: actionFilter,
                  items: [null, ...AuditAction.values],
                  itemLabel: (action) => action == null
                      ? 'Todas las acciones'
                      : auditActionLabel(action),
                  onChanged: onActionFilterChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) =>
                  context.read<AuditProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ListViewState<AuditLogEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AuditProvider>().load(),
        );
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay actividad registrada',
          icon: Icons.history_outlined,
        );
      case ViewStatus.success:
        return DesktopDataTable<AuditLogEntity>(
          items: state.items,
          columns: [
            DesktopDataColumn(
              label: 'Resultado',
              cellBuilder: (log) => Icon(
                auditResultIcon(log),
                size: 18,
                color: auditResultColor(log),
              ),
            ),
            DesktopDataColumn(
              label: 'Acción',
              cellBuilder: (log) => Text(auditActionLabel(log.action)),
            ),
            DesktopDataColumn(
              label: 'Entidad',
              cellBuilder: (log) => Text(auditEntityLabel(log)),
            ),
            DesktopDataColumn(
              label: 'Fecha',
              cellBuilder: (log) => Text(Formatters.dateTime(log.createdAt)),
            ),
          ],
        );
    }
  }
}
