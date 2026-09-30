import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/kept_listing.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile/mobile_card_list.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/mobile/mobile_skeletons.dart';
import '../../../../core/widgets/shared/app_dropdown.dart';
import '../../../../core/widgets/shared/app_empty_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_list_tile.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../../../../core/widgets/shared/app_pagination.dart';
import '../../../../core/widgets/shared/skeleton/skeleton_blocks.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../providers/audit_provider.dart';
import '../shared/audit_labels.dart';

class AuditMobileView extends StatelessWidget {
  const AuditMobileView({
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
          const MobilePageHeader(title: 'Auditoría'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          if (classFiltered)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: const Text('Solo esta clase'),
                  avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                  onDeleted: onClearClassFilter,
                  deleteButtonTooltipMessage: 'Ver toda la actividad',
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state, updating: updating)),
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
        return const MobileListSkeleton(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 88),
          leading: SkeletonLeading.square,
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
          child: MobileCardList<AuditLogEntity>(
            items: state.items,
            footer: AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: onLoadPage,
            ),
            itemBuilder: (context, log) => AppListTile(
              icon: auditResultIcon(log),
              iconColor: auditResultColor(log),
              title: auditActionLabel(log.action),
              subtitle:
                  '${auditEntityLabel(log)} · ${Formatters.dateTime(log.createdAt)}',
              subtitleMaxLines: 2,
            ),
          ),
        );
    }
  }
}
