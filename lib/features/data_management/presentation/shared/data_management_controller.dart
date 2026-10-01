import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../exports/data/export_datasource.dart';
import '../../../imports/domain/entities/import_batch_entity.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';

/// State and actions of the import/export screen: selected class, files
/// picked for each upload, and which export is currently running. Owned by
/// the page entry point so it survives a mobile <-> desktop switch.
class DataManagementController extends ChangeNotifier {
  TeachingPeriodEntity? _period;
  TeachingPeriodEntity? get period => _period;

  PickedFile? _studentsPicked;
  PickedFile? get studentsPicked => _studentsPicked;

  PickedFile? _periodPicked;
  PickedFile? get periodPicked => _periodPicked;

  PickedFile? _schoolSetupPicked;
  PickedFile? get schoolSetupPicked => _schoolSetupPicked;

  /// The download (export or template) currently running, so its button
  /// shows the loading state.
  String? _exportLoadingAction;
  bool isExporting(String action) => _exportLoadingAction == action;

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void selectPeriod(TeachingPeriodEntity? period) =>
      _update(() => _period = period);
  void pickStudents(PickedFile? file) => _update(() => _studentsPicked = file);
  void pickPeriod(PickedFile? file) => _update(() => _periodPicked = file);
  void pickSchoolSetup(PickedFile? file) =>
      _update(() => _schoolSetupPicked = file);

  Future<void> _runExport(
    BuildContext context,
    String action,
    Future<BinaryDownload> Function() fetch, {
    String errorMessage = 'No se pudo generar la exportación.',
  }) async {
    _update(() => _exportLoadingAction = action);
    try {
      await fetchAndSaveFile(context, fetch: fetch, errorMessage: errorMessage);
    } finally {
      _update(() => _exportLoadingAction = null);
    }
  }

  Future<void> downloadStudentsTemplate(BuildContext context) {
    final provider = context.read<ImportsProvider>();
    return _runExport(
      context,
      'studentsTemplate',
      provider.downloadTemplate,
      errorMessage: 'No se pudo descargar la plantilla.',
    );
  }

  Future<void> downloadSchoolSetupTemplate(BuildContext context) {
    final provider = context.read<ImportsProvider>();
    return _runExport(
      context,
      'schoolSetupTemplate',
      provider.downloadSchoolSetupTemplate,
      errorMessage: 'No se pudo descargar la plantilla.',
    );
  }

  Future<void> downloadPeriodFull(BuildContext context) async {
    final period = _period;
    if (period == null) return;
    final dataSource = context.read<ExportDataSource>();
    await _runExport(
      context,
      'full',
      () => dataSource.exportTeachingPeriodFull(teachingPeriodId: period.id),
    );
  }

  Future<void> exportStudents(BuildContext context) async {
    final dataSource = context.read<ExportDataSource>();
    final periodId = _period?.id;
    await _runExport(
      context,
      'students',
      () => dataSource.exportStudents(teachingPeriodId: periodId),
    );
  }

  Future<void> exportGrades(BuildContext context) async {
    final period = _period;
    if (period == null) return;
    final dataSource = context.read<ExportDataSource>();
    await _runExport(
      context,
      'grades',
      () => dataSource.exportGrades(teachingPeriodId: period.id),
    );
  }

  Future<void> exportAttendance(BuildContext context) async {
    final period = _period;
    if (period == null) return;
    final dataSource = context.read<ExportDataSource>();
    await _runExport(
      context,
      'attendance',
      () => dataSource.exportAttendance(teachingPeriodId: period.id),
    );
  }

  Future<void> uploadStudents(BuildContext context) => _upload(
    context,
    ImportType.students,
    _studentsPicked,
    onQueued: () => pickStudents(null),
  );

  Future<void> uploadPeriod(BuildContext context) async {
    final period = _period;
    if (period == null) return;
    await _upload(
      context,
      ImportType.teachingPeriod,
      _periodPicked,
      teachingPeriodId: period.id,
      onQueued: () => pickPeriod(null),
    );
  }

  Future<void> uploadSchoolSetup(BuildContext context) => _upload(
    context,
    ImportType.schoolSetup,
    _schoolSetupPicked,
    onQueued: () => pickSchoolSetup(null),
  );

  /// Sends [file]; once it is queued the picked file is cleared and the
  /// card follows the import. A rejected upload keeps the file to retry.
  Future<void> _upload(
    BuildContext context,
    ImportType type,
    PickedFile? file, {
    int? teachingPeriodId,
    required VoidCallback onQueued,
  }) async {
    if (file == null) return;
    final error = await context.read<ImportsProvider>().upload(
      type,
      fileName: file.name,
      bytes: file.bytes,
      teachingPeriodId: teachingPeriodId,
    );
    if (error == null) {
      onQueued();
    } else if (context.mounted) {
      context.showApiError(error);
    }
  }

  void dismissResult(BuildContext context, ImportType type) =>
      context.read<ImportsProvider>().dismiss(type);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
