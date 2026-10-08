import 'package:flutter/material.dart';

import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_upload_zone.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../shared/exam_import_controller.dart';
import '../shared/exam_import_form.dart';

class ExamImportDesktopView extends StatelessWidget {
  const ExamImportDesktopView({super.key, required this.controller});

  final ExamImportController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          DesktopPageHeader(
            title: 'Importar examen desde Word',
            subtitle:
                'Carga un documento .docx y crea el examen con sus preguntas.',
            onBack: () {
              Navigator.of(context).maybePop();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AppCard(
                  child: ExamImportForm(
                    controller: controller,
                    fileIntake: DesktopUploadZone(
                      allowedExtensions: const ['docx'],
                      title: 'Arrastra aquí el documento Word',
                      subtitle: 'Solo archivos .docx, máximo 60 MB.',
                      onFilePicked: (file) =>
                          controller.pickFile(context, file),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
