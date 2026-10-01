import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cache/synced_data_state.dart';
import '../../../../core/layout/responsive.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../desktop/data_management_desktop_view.dart';
import '../mobile/data_management_mobile_view.dart';
import '../../../teaching/presentation/shared/class_picker.dart';
import '../shared/data_management_controller.dart';

/// Single screen for every Excel import/export flow (the backend unified
/// these behind one set of endpoints, so the UI mirrors that: one place,
/// not a separate "imports" page and "exports" page).
class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage>
    with SyncedDataState<DataManagementPage> {
  final _controller = DataManagementController();

  @override
  void ensureData() {
    context.read<ImportsProvider>().ensureHistory();
    // The class import and exports pick from the teacher's classes.
    if (_controller.period == null) _pickInitialClass();
  }

  Future<void> _pickInitialClass() async {
    final period = await initialClass(context);
    if (!mounted || _controller.period != null || period == null) return;
    _controller.selectPeriod(period);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ResponsiveBuilder(
        mobile: (_) => DataManagementMobileView(controller: _controller),
        desktop: (_) => DataManagementDesktopView(controller: _controller),
      ),
    );
  }
}
