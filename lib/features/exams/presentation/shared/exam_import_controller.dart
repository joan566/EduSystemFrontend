import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/shared/app_download.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../providers/exams_provider.dart';

/// State and actions for importing an exam from a Word document.
class ExamImportController extends ChangeNotifier {
  ExamImportController({required this.teachingPeriodId});

  final int teachingPeriodId;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final maximumScoreController = TextEditingController();

  PickedFile? _file;
  PickedFile? get file => _file;

  DateTime? _evaluationDate;
  DateTime? get evaluationDate => _evaluationDate;

  AppException? _validationError;
  AppException? get validationError => _validationError;

  bool _downloadingTemplate = false;
  bool get downloadingTemplate => _downloadingTemplate;

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void clearFile() => _update(() => _file = null);

  void pickFile(BuildContext context, PickedFile file) {
    if (!file.name.toLowerCase().endsWith('.docx')) {
      context.showError('Selecciona un documento de Word .docx.');
      return;
    }
    final size = file.size ?? file.bytes.length;
    if (size > AppConfig.maxUploadSizeBytes) {
      context.showError('El archivo supera el máximo permitido de 60 MB.');
      return;
    }
    _update(() {
      _file = file;
      _validationError = null;
    });
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _evaluationDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _evaluationDate == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_evaluationDate!),
    );
    if (time == null) return;
    _update(
      () => _evaluationDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void clearDate() => _update(() => _evaluationDate = null);

  Future<void> downloadTemplate(BuildContext context) async {
    _update(() => _downloadingTemplate = true);
    try {
      await fetchAndSaveFile(
        context,
        fetch: () => context.read<ExamsProvider>().downloadExamTemplate(),
        errorMessage: 'No se pudo descargar la plantilla de examen.',
      );
    } finally {
      _update(() => _downloadingTemplate = false);
    }
  }

  Future<void> import(BuildContext context) async {
    final file = _file;
    if (file == null || !formKey.currentState!.validate()) return;
    _update(() => _validationError = null);

    final result = await context.read<ExamsProvider>().importDocument(
      teachingPeriodId: teachingPeriodId,
      fileBytes: file.bytes,
      fileName: file.name,
      name: _optionalText(nameController.text),
      description: _optionalText(descriptionController.text),
      evaluationDate: _evaluationDate,
      maximumScore: double.tryParse(maximumScoreController.text.trim()),
    );
    if (!context.mounted) return;
    final error = result.error;
    if (error != null) {
      if (error.code == 'INVALID_QUESTION_DOCUMENT' &&
          error.fieldErrors.isNotEmpty) {
        _update(() => _validationError = error);
      } else {
        context.showApiError(error);
      }
      return;
    }
    final exam = result.exam;
    if (exam == null) return;
    context.showSuccess('Examen importado correctamente.');
    context.pushReplacement(RoutePaths.examDetail(exam.id));
  }

  String? validateMaximumScore(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un puntaje mayor que cero.';
    }
    return null;
  }

  static String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    descriptionController.dispose();
    maximumScoreController.dispose();
    super.dispose();
  }
}
