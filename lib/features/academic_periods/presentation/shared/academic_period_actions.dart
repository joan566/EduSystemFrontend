import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';
import 'academic_period_form.dart';

/// Persistence + user feedback for academic-period mutations, shared by the
/// mobile and desktop views.
class AcademicPeriodActions {
  AcademicPeriodActions._();

  static Future<bool> save(
    BuildContext context, {
    AcademicPeriodEntity? initial,
    required AcademicPeriodFormResult data,
  }) async {
    final provider = context.read<AcademicPeriodsProvider>();
    final error = initial == null
        ? await provider.create(
            name: data.name,
            startDate: data.startDate,
            endDate: data.endDate,
          )
        : await provider.update(
            initial.id,
            name: data.name,
            startDate: data.startDate,
            endDate: data.endDate,
          );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess(
      initial == null ? 'Periodo creado.' : 'Periodo actualizado.',
    );
    return true;
  }

  static Future<void> delete(
    BuildContext context,
    AcademicPeriodEntity period,
  ) async {
    await showAppConfirmDialog(
      context,
      title: 'Eliminar periodo',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${period.name}"?',
      confirmLabel: 'Eliminar',
      onConfirm: () async {
        final error = await context.read<AcademicPeriodsProvider>().delete(
          period.id,
        );
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          context.showSuccess('Periodo eliminado.');
        }
      },
    );
  }
}
