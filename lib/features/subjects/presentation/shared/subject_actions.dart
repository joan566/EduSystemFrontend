import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subjects_provider.dart';
import 'subject_form.dart';

/// Persistence + user feedback for subject mutations, shared by the mobile
/// and desktop views.
class SubjectActions {
  SubjectActions._();

  static Future<void> save(
    BuildContext context, {
    SubjectEntity? initial,
    required SubjectFormResult data,
  }) async {
    final provider = context.read<SubjectsProvider>();
    final description = data.description.isEmpty ? null : data.description;
    final error = initial == null
        ? await provider.create(name: data.name, description: description)
        : await provider.update(
            initial.id,
            name: data.name,
            description: description,
          );
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        initial == null ? 'Materia creada.' : 'Materia actualizada.',
      );
    }
  }

  static Future<void> delete(
    BuildContext context,
    SubjectEntity subject,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar materia',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${subject.name}"?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<SubjectsProvider>().delete(subject.id);
    if (!context.mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Materia eliminada.');
    }
  }
}
