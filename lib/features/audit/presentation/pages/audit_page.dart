import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
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

class _AuditPageState extends State<AuditPage> {
  AuditAction? _actionFilter;
  late int? _teachingPeriodId = widget.initialTeachingPeriodId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage(0));
  }

  void _onActionFilterChanged(AuditAction? action) {
    setState(() => _actionFilter = action);
    _loadPage(0);
  }

  void _clearClassFilter() {
    setState(() => _teachingPeriodId = null);
    _loadPage(0);
  }

  /// Every load (first page, pagination, retry) goes through here so the
  /// active filters are never dropped.
  void _loadPage(int page) => context.read<AuditProvider>().load(
    page: page,
    action: auditActionApiValues[_actionFilter],
    teachingPeriodId: _teachingPeriodId,
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AuditMobileView(
        actionFilter: _actionFilter,
        classFiltered: _teachingPeriodId != null,
        onClearClassFilter: _clearClassFilter,
        onLoadPage: _loadPage,
        onActionFilterChanged: _onActionFilterChanged,
      ),
      desktop: (_) => AuditDesktopView(
        actionFilter: _actionFilter,
        classFiltered: _teachingPeriodId != null,
        onClearClassFilter: _clearClassFilter,
        onLoadPage: _loadPage,
        onActionFilterChanged: _onActionFilterChanged,
      ),
    );
  }
}
