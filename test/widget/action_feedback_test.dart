import 'dart:async';

import 'package:edusistem_front/core/widgets/desktop/desktop_dialog.dart';
import 'package:edusistem_front/core/widgets/shared/app_async_button.dart';
import 'package:edusistem_front/core/widgets/shared/app_confirm_dialog.dart';
import 'package:edusistem_front/features/academic_levels/presentation/shared/academic_level_form.dart';
import 'package:edusistem_front/features/exams/domain/entities/submission_entity.dart';
import 'package:edusistem_front/features/exams/presentation/shared/submission_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen with one button that runs [onPressed] with its context.
Widget _host(void Function(BuildContext context) onPressed) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => onPressed(context),
        child: const Text('abrir'),
      ),
    ),
  ),
);

void main() {
  testWidgets('a confirm with onConfirm stays open and loading until done', (
    tester,
  ) async {
    final deleting = Completer<void>();
    bool? confirmed;
    await tester.pumpWidget(
      _host((context) async {
        confirmed = await showAppConfirmDialog(
          context,
          title: 'Eliminar grado',
          message: '¿Eliminar?',
          confirmLabel: 'Eliminar',
          onConfirm: () => deleting.future,
        );
      }),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    expect(find.text('Eliminar grado'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Cancel and back are blocked while it runs.
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Eliminar grado'), findsOneWidget);

    deleting.complete();
    await tester.pumpAndSettle();
    expect(find.text('Eliminar grado'), findsNothing);
    expect(confirmed, isTrue);
  });

  testWidgets('AppAsyncButton loads while its future runs', (tester) async {
    final download = Completer<void>();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAsyncButton(
            label: 'Descargar plantilla',
            onPressed: () {
              taps++;
              return download.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Descargar plantilla'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Descargar plantilla'));
    expect(taps, 1);

    download.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a form keeps what was typed when the save fails', (
    tester,
  ) async {
    var answer = Completer<bool>();
    await tester.pumpWidget(
      _host(
        (context) => showDesktopDialog<void>(
          context,
          child: AcademicLevelForm(onSubmit: (_) => answer.future),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10°');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    answer.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Nuevo grado'), findsOneWidget);
    expect(find.text('10°'), findsOneWidget);

    answer = Completer<bool>();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    answer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Nuevo grado'), findsNothing);
  });

  testWidgets('closing "Corregir pregunta" without picking changes nothing', (
    tester,
  ) async {
    const answer = SubmissionAnswer(
      questionNumber: 3,
      statement: '¿2 + 2?',
      selectedOption: 'B',
      correctOption: 'B',
      detectionStatus: DetectionStatus.marked,
      needsReview: false,
    );
    final submitted = <String?>[];
    await tester.pumpWidget(
      _host(
        (context) => showDesktopDialog<void>(
          context,
          child: CorrectAnswerForm(
            answer: answer,
            onSubmit: (option) async {
              submitted.add(option);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Corregir pregunta 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Corregir pregunta 3'), findsNothing);
    expect(submitted, isEmpty);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin respuesta'));
    await tester.pumpAndSettle();
    expect(submitted, [null]);
    expect(find.text('Corregir pregunta 3'), findsNothing);
  });
}
