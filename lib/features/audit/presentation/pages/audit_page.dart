import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../desktop/audit_desktop_view.dart';
import '../mobile/audit_mobile_view.dart';
import '../providers/audit_provider.dart';
import '../shared/audit_labels.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  AuditAction? _actionFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuditProvider>().load(),
    );
  }

  void _onActionFilterChanged(AuditAction? action) {
    setState(() => _actionFilter = action);
    context.read<AuditProvider>().load(action: auditActionApiValues[action]);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AuditMobileView(
        actionFilter: _actionFilter,
        onActionFilterChanged: _onActionFilterChanged,
      ),
      desktop: (_) => AuditDesktopView(
        actionFilter: _actionFilter,
        onActionFilterChanged: _onActionFilterChanged,
      ),
    );
  }
}
