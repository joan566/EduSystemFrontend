import 'package:edusistem_front/core/widgets/shared/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton invokes onPressed when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Guardar', onPressed: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppButton shows a spinner and ignores taps while loading', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Guardando...',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Guardando...'), warnIfMissed: false);
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('AppButton is disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(label: 'Deshabilitado', onPressed: null)),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
