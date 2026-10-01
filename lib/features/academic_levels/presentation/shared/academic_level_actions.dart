import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/academic_level_entity.dart';
import '../providers/academic_levels_provider.dart';
import 'academic_level_form.dart';

/// Persistence + user feedback for academic-level mutations. Shared by the
/// mobile and desktop views: each presents the form its own way, then
/// hands the result here.
class AcademicLevelActions {
  AcademicLevelActions._();

  static Future<bool> save(
    BuildContext context, {
    AcademicLevelEntity? initial,
    required AcademicLevelFormResult data,
  }) async {
    final provider = context.read<AcademicLevelsProvider>();
    final description = data.description.isEmpty ? null : data.description;
    final error = initial == null
        ? await provider.create(name: data.name, description: description)
        : await provider.update(
            initial.id,
            name: data.name,
            description: description,
          );
    if (!context.mounted) return error == null;
    if (error != null) {
      context.showApiError(error);
      return false;
    }
    context.showSuccess(
      initial == null ? 'Grado creado.' : 'Grado actualizado.',
    );
    return true;
  }

  static Future<void> delete(
    BuildContext context,
    AcademicLevelEntity level,
  ) async {
    await showAppConfirmDialog(
      context,
      title: 'Eliminar grado',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${level.name}"?',
      confirmLabel: 'Eliminar',
      onConfirm: () async {
        final error = await context.read<AcademicLevelsProvider>().delete(
          level.id,
        );
        if (!context.mounted) return;
        if (error != null) {
          context.showApiError(error);
        } else {
          context.showSuccess('Grado eliminado.');
        }
      },
    );
  }
}
