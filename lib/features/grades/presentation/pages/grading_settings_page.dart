import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/grading_settings_desktop_view.dart';
import '../mobile/grading_settings_mobile_view.dart';
import '../shared/grading_configuration_controller.dart';

/// "Configuración de notas": a class's grading scale, passing grade and
/// category weights. Separate from the grades on purpose: it's setup,
/// done once per class, not day-to-day administration.
class GradingSettingsPage extends StatefulWidget {
  const GradingSettingsPage({super.key, this.initialTeachingPeriodId});

  final int? initialTeachingPeriodId;

  @override
  State<GradingSettingsPage> createState() => _GradingSettingsPageState();
}

class _GradingSettingsPageState extends State<GradingSettingsPage> {
  // The class and its edits live here so they survive a layout switch.
  TeachingPeriodEntity? _period;
  GradingConfigurationController? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final teaching = context.read<TeachingProvider>();
      await teaching.ensureAllPeriodsLoaded();
      if (!mounted || _period != null || teaching.allPeriods.isEmpty) return;
      final preferred = teaching.allPeriods
          .where((p) => p.id == widget.initialTeachingPeriodId)
          .firstOrNull;
      _onPeriodChanged(preferred ?? teaching.allPeriods.first);
    });
  }

  void _onPeriodChanged(TeachingPeriodEntity? period) {
    if (period == null || period.id == _period?.id) return;
    _config?.dispose();
    final config = GradingConfigurationController(period.id);
    setState(() {
      _period = period;
      _config = config;
    });
    config.load(context);
  }

  @override
  void dispose() {
    _config?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => GradingSettingsMobileView(
        period: _period,
        config: _config,
        onPeriodChanged: _onPeriodChanged,
      ),
      desktop: (_) => GradingSettingsDesktopView(
        period: _period,
        config: _config,
        onPeriodChanged: _onPeriodChanged,
      ),
    );
  }
}
