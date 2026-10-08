import 'package:flutter/material.dart';

import '../../../../core/widgets/mobile/mobile_file_picker_button.dart';
import '../shared/exam_import_controller.dart';
import '../shared/exam_import_form.dart';

class ExamImportMobileView extends StatelessWidget {
  const ExamImportMobileView({super.key, required this.controller});

  final ExamImportController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar examen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExamImportForm(
            controller: controller,
            fileIntake: MobileFilePickerButton(
              allowedExtensions: const ['docx'],
              label: 'Seleccionar documento .docx',
              hint: 'Documento Word, máximo 60 MB.',
              onFilePicked: (file) => controller.pickFile(context, file),
            ),
          ),
        ],
      ),
    );
  }
}
