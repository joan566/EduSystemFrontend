import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/mobile/mobile_file_picker_button.dart';
import '../../../../core/widgets/mobile/mobile_form.dart';
import '../../../../core/widgets/mobile/mobile_page_header.dart';
import '../../../../core/widgets/shared/app_card.dart';
import '../../../../core/widgets/shared/picked_file.dart';
import '../../../imports/presentation/providers/imports_provider.dart';
import '../../../teaching/presentation/mobile/class_picker_sheet.dart';
import '../shared/data_management_controller.dart';
import '../shared/data_management_sections.dart';
import '../shared/data_management_widgets.dart';

/// Mobile: one column of cards, file picker buttons instead of drop zones.
class DataManagementMobileView extends StatelessWidget {
  const DataManagementMobileView({super.key, required this.controller});

  final DataManagementController controller;

  Widget _intake(ValueChanged<PickedFile> onFilePicked) =>
      MobileFilePickerButton(
        allowedExtensions: const ['xlsx'],
        label: 'Seleccionar archivo .xlsx',
        hint: 'Máximo 15 MB',
        onFilePicked: onFilePicked,
      );

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ImportsProvider>().historyState;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const MobilePageHeader(title: 'Importar y exportar'),
          SchoolSetupCard(controller: controller, intake: _intake),
          const SizedBox(height: 20),
          Text('Datos de una clase específica', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          MobileClassPickerCard(
            value: controller.period,
            onChanged: controller.selectPeriod,
            showLabel: true,
          ),
          const SizedBox(height: 6),
          Text(
            'Opcional para estudiantes, requerida para el resto.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Plantillas de esta clase', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Elige cuál necesitas descargar.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final (i, option) in classTemplateOptions(
                  context,
                  controller,
                ).indexed) ...[if (i > 0) const SizedBox(height: 12), option],
              ],
            ),
          ),
          const SizedBox(height: 12),
          PeriodUploadCard(controller: controller, intake: _intake),
          const SizedBox(height: 12),
          StudentsUploadCard(controller: controller, intake: _intake),
          const SizedBox(height: 12),
          SeparateExportsCard(controller: controller),
          const SizedBox(height: 20),
          Text('Historial de importaciones', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ImportHistoryList(
            state: history,
            onOpen: (batch) => showMobileSheet<void>(
              context,
              builder: (_) => ImportBatchDetail(batch: batch),
            ),
          ),
        ],
      ),
    );
  }
}
