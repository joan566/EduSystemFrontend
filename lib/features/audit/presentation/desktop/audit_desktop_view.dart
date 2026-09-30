import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/kept_listing.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop/desktop_data_table.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_skeletons.dart';
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
    required this.classFiltered,
    required this.onClearClassFilter,
    required this.onLoadPage,
    required this.onActionFilterChanged,
    required this.query,
    required this.onRetry,
    required this.listing,
  });

  /// The page and filters on screen.
  final AuditQuery query;
  final VoidCallback onRetry;

  /// Keeps the previous rows visible while another page/filter loads.
  final KeptListing<AuditLogEntity> listing;

  final AuditAction? actionFilter;

  /// Whether only one class's actions are shown.
  final bool classFiltered;
  final VoidCallback onClearClassFilter;

  /// Loads a page keeping the active filters.
  final ValueChanged<int> onLoadPage;
  final ValueChanged<AuditAction?> onActionFilterChanged;

  @override
  Widget build(BuildContext context) {
    final (:state, :updating) = listing.resolve(
      context.watch<AuditProvider>().feed(query),
    );

    return Scaffold(
      body: Column(
        children: [
          const DesktopPageHeader(
            title: 'Auditoría',
            subtitle: 'Historial de acciones realizadas en tu cuenta.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                SizedBox(
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
                if (classFiltered) ...[
                  const SizedBox(width: 12),
                  InputChip(
                    label: const Text('Solo esta clase'),
                    avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                    onDeleted: onClearClassFilter,
                    deleteButtonTooltipMessage: 'Ver toda la actividad',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state, updating: updating)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: onLoadPage,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ListViewState<AuditLogEntity> state, {
    required bool updating,
  }) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const DesktopDataTableSkeleton(
          rows: 12,
          columns: [
            SkeletonColumn('Resultado', cell: SkeletonCell.value),
            SkeletonColumn('Acción', flex: 2),
            SkeletonColumn('Entidad', flex: 2),
            SkeletonColumn('Fecha', flex: 2),
          ],
        );
      case ViewStatus.error:
        return AppErrorState(exception: state.error!, onRetry: onRetry);
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay actividad registrada',
          icon: Icons.history_outlined,
        );
      case ViewStatus.success:
        return AppUpdating(
          updating: updating,
          child: DesktopDataTable<AuditLogEntity>(
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
          ),
        );
    }
  }
}
