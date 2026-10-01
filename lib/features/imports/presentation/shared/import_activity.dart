import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../domain/entities/import_batch_entity.dart';
import '../providers/imports_provider.dart';

/// "Importando Estudiantes · 120 de 450 filas", "En cola…" — where a
/// running import is, as its card, the history and the shell show it.
String importProgressLabel(ImportBatchEntity batch) {
  if (batch.status == ImportStatus.queued) return 'En cola…';
  final step = batch.currentStep;
  final title = step == null ? 'Importando…' : 'Importando $step';
  final processed = batch.processedRows;
  final total = batch.totalRows;
  if (processed == null || total == null || total == 0) return title;
  return '$title · $processed de $total filas';
}

/// [importProgressLabel] for an upload, which starts by sending the file.
String importRunLabel(ImportRun run) => switch (run.phase) {
  ImportPhase.uploading => 'Subiendo archivo…',
  _ when run.batch != null => importProgressLabel(run.batch!),
  _ => 'Importando…',
};

/// 0..1 of a running upload; null for an indeterminate bar (queued, or a
/// backend that doesn't report progress).
double? importRunProgress(ImportRun run) => switch (run.phase) {
  ImportPhase.uploading => run.uploadProgress,
  _ => run.batch?.progress,
};

/// True on the import/export screen, which shows the import in full: the
/// shell's indicator and completion notice stay out of its way.
bool isOnDataManagement(BuildContext context) =>
    GoRouterState.of(context).uri.path.startsWith(RoutePaths.dataManagement);

/// Tells the teacher when an import finishes while they are elsewhere in
/// the app. Mounted once by the shell, above the mobile/desktop fork, so
/// the notice shows once whatever the layout.
class ImportCompletionListener extends StatefulWidget {
  const ImportCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  State<ImportCompletionListener> createState() =>
      _ImportCompletionListenerState();
}

class _ImportCompletionListenerState extends State<ImportCompletionListener> {
  late final ImportsProvider _imports;

  /// Each type's run as last seen, to notice the moment it finishes.
  final Map<ImportType, ImportRun?> _seen = {};

  @override
  void initState() {
    super.initState();
    _imports = context.read<ImportsProvider>();
    for (final type in ImportType.values) {
      _seen[type] = _imports.run(type);
    }
    _imports.addListener(_onChanged);
  }

  void _onChanged() {
    for (final type in ImportType.values) {
      final before = _seen[type];
      final now = _imports.run(type);
      _seen[type] = now;
      final result = now?.result;
      if (identical(before, now) || result == null) continue;
      if (before == null || before.phase == ImportPhase.finished) continue;
      if (!mounted || isOnDataManagement(context)) continue;
      _notify(result.batch);
    }
  }

  void _notify(ImportBatchEntity batch) {
    final total = batch.totalRows ?? 0;
    final ok = batch.successfulRows ?? 0;
    if (batch.failedWholeFile) {
      context.showError('No se pudo importar ${batch.fileName}.');
    } else if (batch.status == ImportStatus.completed) {
      context.showSuccess(
        'Importación completada: $total ${total == 1 ? 'fila' : 'filas'}.',
      );
    } else {
      context.showWarning(
        'Importación terminada con errores: $ok de $total filas correctas. '
        'Revisa el detalle en Importar y exportar.',
      );
    }
  }

  @override
  void dispose() {
    _imports.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
