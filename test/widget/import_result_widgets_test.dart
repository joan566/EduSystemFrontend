import 'package:edusistem_front/features/data_management/presentation/shared/data_management_widgets.dart';
import 'package:edusistem_front/features/imports/data/models/import_batch_model.dart';
import 'package:edusistem_front/features/imports/presentation/providers/imports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('a queued or running import says so', (tester) async {
    final queued = ImportBatchModel.fromJson(importJson(1, 'QUEUED'));
    await tester.pumpWidget(
      _wrap(
        ImportProgressPanel(
          run: ImportRun(phase: ImportPhase.queued, batch: queued),
        ),
      ),
    );
    expect(find.text('En cola…'), findsOneWidget);
    expect(
      find.textContaining('Puedes salir de esta pantalla'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _wrap(
        ImportProgressPanel(
          run: ImportRun(phase: ImportPhase.processing, batch: queued),
        ),
      ),
    );
    expect(find.text('Importando…'), findsOneWidget);
  });

  testWidgets('a rejected file shows the backend message, no counts', (
    tester,
  ) async {
    final result = ImportBatchModel.resultFromJson(
      importJson(
        2,
        'FAILED',
        errorCode: 'MISSING_COLUMNS',
        errorMessage: 'Faltan columnas obligatorias: Nombres',
      ),
    );
    await tester.pumpWidget(
      _wrap(ImportResultSummary(result: result, onDismiss: () {})),
    );
    expect(find.text('No se pudo importar el archivo'), findsOneWidget);
    expect(find.text('Faltan columnas obligatorias: Nombres'), findsOneWidget);
    expect(find.textContaining('correctas'), findsNothing);
  });

  testWidgets('a partial import lists its row errors', (tester) async {
    final result = ImportBatchModel.resultFromJson(
      importJson(
        3,
        'COMPLETED_WITH_ERRORS',
        total: 8,
        successful: 2,
        errors: const [
          {'row': 3, 'column': 'Nombres', 'message': 'Obligatorio'},
        ],
        errorsTruncated: true,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        ImportResultSummary(
          result: result,
          onDownloadErrors: () async {},
          onDismiss: () {},
        ),
      ),
    );
    expect(find.text('8 filas procesadas'), findsOneWidget);
    expect(find.text('2 correctas · 6 errores'), findsOneWidget);
    expect(find.text('Fila 3 (Nombres): Obligatorio'), findsOneWidget);
    expect(
      find.textContaining('Se muestran los primeros 1 errores'),
      findsOneWidget,
    );
    expect(find.text('Descargar reporte de errores'), findsOneWidget);
  });
}
