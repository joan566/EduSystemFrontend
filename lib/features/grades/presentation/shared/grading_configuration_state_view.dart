import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_error_state.dart';
import '../../../../core/widgets/shared/app_loading.dart';
import '../providers/grading_provider.dart';
import 'grading_configuration_controller.dart';

/// Resolves the configuration's loading/error states and rebuilds [builder]
/// on every edit; each platform's view only lays the editor out.
class GradingConfigurationStateView extends StatelessWidget {
  const GradingConfigurationStateView({
    super.key,
    required this.controller,
    required this.builder,
  });

  final GradingConfigurationController controller;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final configState = context.watch<GradingProvider>().configuration(
      controller.teachingPeriodId,
    );
    switch (configState.status) {
      case DetailStatus.initial:
      case DetailStatus.loading:
        return const AppLoading();
      case DetailStatus.error:
        return AppErrorState(
          exception: configState.error!,
          onRetry: () => controller.load(context, refresh: true),
        );
      case DetailStatus.success:
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => builder(context),
        );
    }
  }
}

/// "Configuración válida" / "Faltan 20%" / "Sobra 10%" for a weights total.
({String label, bool valid}) weightsTotalStatus(double total) {
  final diff = 100 - total;
  if (diff.abs() < 0.001) return (label: 'Configuración válida', valid: true);
  final amount = diff.abs() == diff.abs().roundToDouble()
      ? diff.abs().toStringAsFixed(0)
      : diff.abs().toStringAsFixed(1);
  return diff > 0
      ? (label: 'Faltan $amount%', valid: false)
      : (label: 'Sobra $amount%', valid: false);
}
