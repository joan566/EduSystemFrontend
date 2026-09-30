import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/state/kept_listing.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../desktop/audit_desktop_view.dart';
import '../mobile/audit_mobile_view.dart';
import '../providers/audit_provider.dart';
import '../shared/audit_labels.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key, this.initialTeachingPeriodId});

  /// Shows only one class's actions (from `?teachingPeriodId=`), e.g. when
  /// opened from that class's "Actividad reciente".
  final int? initialTeachingPeriodId;

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> with SyncedDataState<AuditPage> {
  AuditAction? _actionFilter;
  late int? _teachingPeriodId = widget.initialTeachingPeriodId;
  int _page = 0;

  /// The rows on screen stay while another page or filter loads.
  final _listing = KeptListing<AuditLogEntity>();

  /// The page and filters on screen, so they are never dropped.
  AuditQuery get _query => (
    page: _page,
    action: auditActionApiValues[_actionFilter],
    teachingPeriodId: _teachingPeriodId,
  );

  /// A page already seen comes from memory until something changes (or
  /// [AuditProvider.maxAge] passes).
  @override
  void ensureData() => context.read<AuditProvider>().ensureFeed(_query);

  void _onActionFilterChanged(AuditAction? action) {
    setState(() {
      _actionFilter = action;
      _page = 0;
    });
    ensureData();
  }

  void _clearClassFilter() {
    setState(() {
      _teachingPeriodId = null;
      _page = 0;
    });
    ensureData();
  }

  void _loadPage(int page) {
    setState(() => _page = page);
    ensureData();
  }

  void _retry() => context.read<AuditProvider>().refreshFeed(_query);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AuditMobileView(
        actionFilter: _actionFilter,
        classFiltered: _teachingPeriodId != null,
        onClearClassFilter: _clearClassFilter,
        onLoadPage: _loadPage,
        onActionFilterChanged: _onActionFilterChanged,
        query: _query,
        onRetry: _retry,
        listing: _listing,
      ),
      desktop: (_) => AuditDesktopView(
        actionFilter: _actionFilter,
        classFiltered: _teachingPeriodId != null,
        onClearClassFilter: _clearClassFilter,
        onLoadPage: _loadPage,
        onActionFilterChanged: _onActionFilterChanged,
        query: _query,
        onRetry: _retry,
        listing: _listing,
      ),
    );
  }
}
