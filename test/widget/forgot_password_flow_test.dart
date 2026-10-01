import 'dart:async';

import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/storage/token_storage.dart';
import 'package:edusistem_front/features/auth/domain/entities/user_entity.dart';
import 'package:edusistem_front/features/auth/domain/repositories/auth_repository.dart';
import 'package:edusistem_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:edusistem_front/features/auth/presentation/shared/forgot_password_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthProvider authProvider;

  const email = 'ana@escuela.edu';

  setUp(() {
    repository = _MockAuthRepository();
    authProvider = AuthProvider(
      repository: repository,
      apiClient: ApiClient(onSessionExpired: () async {}),
    );
  });

  Widget buildTestable() => ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: Scaffold(
        body: ForgotPasswordFlow(
          builder: (context, onBack, content) =>
              SingleChildScrollView(child: content),
        ),
      ),
    ),
  );

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('each step shows the request running and blocks a second tap', (
    tester,
  ) async {
    final sendCode = Completer<void>();
    final verifying = Completer<void>();
    when(
      () => repository.forgotPassword(email),
    ).thenAnswer((_) => sendCode.future);
    when(
      () => repository.verifyCode(email: email, code: '123456'),
    ).thenAnswer((_) => verifying.future);

    await tester.pumpWidget(buildTestable());
    await tester.enterText(find.byType(TextFormField), email);
    await tester.tap(find.text('Enviar código'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);

    sendCode.complete();
    await tester.pumpAndSettle();
    expect(find.text('Verifica tu correo'), findsOneWidget);
    expect(find.text('Te enviamos un código a $email.'), findsOneWidget);
    expect(find.text('¿No te llegó? Reenviar código'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar código'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);

    verifying.complete();
    await tester.pumpAndSettle();
    expect(find.text('Nueva contraseña'), findsWidgets);
    verify(() => repository.verifyCode(email: email, code: '123456')).called(1);
  });

  testWidgets('a wrong code keeps the step and shows why', (tester) async {
    when(() => repository.forgotPassword(email)).thenAnswer((_) async {});
    when(() => repository.verifyCode(email: email, code: '000000')).thenThrow(
      const AppException(
        code: AppErrorCode.invalidVerificationCode,
        message: 'Invalid code',
        statusCode: 400,
      ),
    );

    await tester.pumpWidget(buildTestable());
    await tester.enterText(find.byType(TextFormField), email);
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verificar código'));
    await tester.pumpAndSettle();

    expect(find.text('Verifica tu correo'), findsOneWidget);
    expect(find.text('El código no es válido o ya expiró.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('changing the password never looks like a sign-out', () async {
    final user = UserEntity(
      id: 1,
      firstName: 'Ana',
      lastName: 'Pérez',
      email: email,
      active: true,
      roles: const ['TEACHER'],
      createdAt: DateTime(2026, 1, 1),
    );
    final tokens = AuthTokens(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: DateTime(2100),
    );
    when(
      () => repository.login(email: email, password: 'password123'),
    ).thenAnswer((_) async => (tokens, user));
    await authProvider.login(email: email, password: 'password123');
    expect(authProvider.status, AuthStatus.authenticated);

    final change = Completer<(AuthTokens, UserEntity)>();
    when(
      () => repository.changePassword(
        currentPassword: 'password123',
        newPassword: 'password456',
      ),
    ).thenAnswer((_) => change.future);

    final statuses = <AuthStatus>[];
    authProvider.addListener(() => statuses.add(authProvider.status));
    final result = authProvider.changePassword(
      currentPassword: 'password123',
      newPassword: 'password456',
    );
    expect(authProvider.isBusy, isTrue);

    change.complete((tokens, user));
    expect(await result, isTrue);
    expect(authProvider.isBusy, isFalse);
    expect(statuses, everyElement(AuthStatus.authenticated));
  });
}
