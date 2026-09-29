import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../exports/data/export_datasource.dart';
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
    Future<BinaryDownload> Function() fetch,
  ) async {
    _update(() => _exportLoadingAction = action);
    try {
      await fetchAndSaveFile(
        context,
        fetch: fetch,
        errorMessage: 'No se pudo generar la exportación.',
      );
    } finally {
      _update(() => _exportLoadingAction = null);
    }
  }

  Future<void> downloadStudentsTemplate(BuildContext context) {
    final provider = context.read<ImportsProvider>();
    return fetchAndSaveFile(
      context,
      fetch: provider.downloadTemplate,
      errorMessage: 'No se pudo descargar la plantilla.',
    );
  }

  Future<void> downloadSchoolSetupTemplate(BuildContext context) {
    final provider = context.read<ImportsProvider>();
    return fetchAndSaveFile(
      context,
      fetch: provider.downloadSchoolSetupTemplate,
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

  Future<void> uploadStudents(BuildContext context) async {
    final file = _studentsPicked;
    if (file == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.upload(fileName: file.name, bytes: file.bytes);
    if (!context.mounted) return;
    if (provider.uploadStatus == UploadStatus.error &&
        provider.uploadError != null) {
      context.showApiError(provider.uploadError!);
    }
  }

  Future<void> uploadPeriod(BuildContext context) async {
    final file = _periodPicked;
    final period = _period;
    if (file == null || period == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.uploadTeachingPeriod(
      teachingPeriodId: period.id,
      fileName: file.name,
      bytes: file.bytes,
    );
    if (!context.mounted) return;
    if (provider.periodUploadStatus == UploadStatus.error &&
        provider.periodUploadError != null) {
      context.showApiError(provider.periodUploadError!);
    }
  }

  Future<void> uploadSchoolSetup(BuildContext context) async {
    final file = _schoolSetupPicked;
    if (file == null) return;
    final provider = context.read<ImportsProvider>();
    await provider.uploadSchoolSetup(fileName: file.name, bytes: file.bytes);
    if (!context.mounted) return;
    if (provider.schoolSetupUploadStatus == UploadStatus.error &&
        provider.schoolSetupUploadError != null) {
      context.showApiError(provider.schoolSetupUploadError!);
    }
  }

  void dismissStudentsResult(BuildContext context) {
    context.read<ImportsProvider>().resetUpload();
    pickStudents(null);
  }

  void dismissPeriodResult(BuildContext context) {
    context.read<ImportsProvider>().resetPeriodUpload();
    pickPeriod(null);
  }

  void dismissSchoolSetupResult(BuildContext context) {
    context.read<ImportsProvider>().resetSchoolSetupUpload();
    pickSchoolSetup(null);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
