import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/desktop/desktop_dialog.dart';
import '../../../../core/widgets/desktop/desktop_page_header.dart';
import '../../../../core/widgets/desktop/desktop_upload_zone.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../../../teaching/presentation/desktop/class_picker_field.dart';
import '../shared/data_management_controller.dart';
import '../shared/data_management_sections.dart';
import '../shared/data_management_widgets.dart';

/// Desktop: drag & drop zones, templates side by side, and the two
/// class-scoped uploads next to each other.
class DataManagementDesktopView extends StatelessWidget {
  const DataManagementDesktopView({super.key, required this.controller});

  final DataManagementController controller;

  Widget _intake(ValueChanged<PickedFile> onFilePicked) => DesktopUploadZone(
    allowedExtensions: const ['xlsx'],
    title: 'Arrastra tu archivo aquí',
    subtitle: 'Solo archivos .xlsx, máximo 15 MB',
    onFilePicked: onFilePicked,
  );

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ImportsProvider>().historyState;
    final textTheme = Theme.of(context).textTheme;
    final templates = classTemplateOptions(context, controller);

    return Scaffold(
      body: ListView(
        children: [
          const DesktopPageHeader(
            title: 'Importar y exportar',
            subtitle:
                'Sube o descarga estudiantes, calificaciones y asistencia en Excel.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SchoolSetupCard(controller: controller, intake: _intake),
                const SizedBox(height: 24),
                Text(
                  'Datos de una clase específica',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DesktopClassPickerField(
                      value: controller.period,
                      onChanged: controller.selectPeriod,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Opcional para estudiantes, requerida para el resto.',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Plantillas de esta clase',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige cuál necesitas descargar.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, option) in templates.indexed) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: option),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PeriodUploadCard(
                        controller: controller,
                        intake: _intake,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StudentsUploadCard(
                        controller: controller,
                        intake: _intake,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SeparateExportsCard(controller: controller),
                const SizedBox(height: 24),
                Text(
                  'Historial de importaciones',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ImportHistoryList(
                  state: history,
                  onOpen: (batch) => showDesktopDialog<void>(
                    context,
                    child: ImportBatchDetail(batch: batch),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
