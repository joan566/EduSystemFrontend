import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/router/route_paths.dart';
import 'package:edusistem_front/features/auth/domain/entities/user_entity.dart';
import 'package:edusistem_front/features/auth/domain/repositories/auth_repository.dart';
import 'package:edusistem_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:edusistem_front/features/auth/presentation/shared/verify_email_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthProvider authProvider;

  const email = 'ana@escuela.edu';
  final user = UserEntity(
    id: 1,
    firstName: 'Ana',
    lastName: 'Pérez',
    email: email,
    active: true,
    roles: const ['TEACHER'],
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = _MockAuthRepository();
    authProvider = AuthProvider(
      repository: repository,
      apiClient: ApiClient(onSessionExpired: () async {}),
    );
  });

  Future<void> registerAna() async {
    when(
      () => repository.register(
        firstName: 'Ana',
        lastName: 'Pérez',
        email: email,
        password: 'password123',
      ),
    ).thenAnswer((_) async => user);
    await authProvider.register(
      firstName: 'Ana',
      lastName: 'Pérez',
      email: email,
      password: 'password123',
    );
  }

  Widget buildTestable() {
    final router = GoRouter(
      initialLocation: RoutePaths.verifyEmail,
      routes: [
        GoRoute(
          path: RoutePaths.verifyEmail,
          builder: (_, _) => const Scaffold(body: VerifyEmailForm()),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (_, _) => const Scaffold(body: Text('login screen')),
        ),
      ],
    );
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  test('register leaves the account pending verification without a session', () async {
    await registerAna();

    expect(authProvider.status, AuthStatus.unauthenticated);
    expect(authProvider.user, isNull);
    expect(authProvider.pendingVerificationEmail, email);
  });

  test('a login rejected with EMAIL_NOT_VERIFIED remembers the email to verify', () async {
    when(() => repository.login(email: email, password: 'password123')).thenThrow(
      const AppException(
        code: AppErrorCode.emailNotVerified,
        message: 'The email address has not been verified',
        statusCode: 403,
      ),
    );

    final ok = await authProvider.login(email: email, password: 'password123');

    expect(ok, isFalse);
    expect(authProvider.status, AuthStatus.unauthenticated);
    expect(authProvider.error?.code, AppErrorCode.emailNotVerified);
    expect(authProvider.pendingVerificationEmail, email);
  });

  testWidgets('verifies the code and sends the user to login', (tester) async {
    await registerAna();
    when(
      () => repository.verifyEmail(email: email, code: '123456'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestable());
    expect(find.textContaining(email), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar correo'));
    await tester.pumpAndSettle();

    verify(() => repository.verifyEmail(email: email, code: '123456')).called(1);
    expect(find.text('login screen'), findsOneWidget);
    expect(authProvider.pendingVerificationEmail, isNull);
  });

  testWidgets('rejects a malformed code without calling the backend', (tester) async {
    await registerAna();
    await tester.pumpWidget(buildTestable());

    await tester.enterText(find.byType(TextFormField), '12ab');
    await tester.tap(find.text('Verificar correo'));
    await tester.pump();

    expect(find.text('El código debe tener 6 dígitos.'), findsOneWidget);
    verifyNever(
      () => repository.verifyEmail(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    );
  });

  testWidgets('resends the verification code', (tester) async {
    await registerAna();
    when(() => repository.resendVerification(email)).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestable());
    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();

    verify(() => repository.resendVerification(email)).called(1);
    expect(find.text('Te enviamos un nuevo código.'), findsOneWidget);
  });

  testWidgets('without a pending account it points the user to login', (tester) async {
    await tester.pumpWidget(buildTestable());

    expect(find.text('Ir a iniciar sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
