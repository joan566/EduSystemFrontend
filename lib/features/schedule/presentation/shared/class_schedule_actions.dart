import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/schedule_entities.dart';
import '../providers/schedule_provider.dart';
import 'class_schedule_form.dart';

/// Weekly-block mutations with user feedback, shared by both views. A
/// clash with another of the teacher's classes comes back as 409
/// SCHEDULE_CONFLICT, whose message names the other class.
class ClassScheduleActions {
  ClassScheduleActions._();

  static Future<void> save(
    BuildContext context, {
    required int teachingPeriodId,
    ClassScheduleEntity? initial,
    required ClassScheduleFormResult data,
  }) async {
    final error = await context.read<ScheduleProvider>().saveClassSchedule(
      teachingPeriodId,
      scheduleId: initial?.id,
      dayOfWeek: data.dayOfWeek,
      startTime: data.startTime,
      endTime: data.endTime,
      room: data.room.isEmpty ? null : data.room,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        initial == null ? 'Bloque agregado.' : 'Bloque actualizado.',
      );
    }
  }

  static Future<void> delete(
    BuildContext context, {
    required int teachingPeriodId,
    required ClassScheduleEntity block,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar bloque',
      message: '¿Quitar este bloque del horario de la clase?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<ScheduleProvider>().deleteClassSchedule(
      teachingPeriodId,
      block.id,
    );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Bloque eliminado.');
    }
  }
}
