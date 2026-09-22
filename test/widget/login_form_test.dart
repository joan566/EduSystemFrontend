import 'package:edusistem_front/core/network/api_client.dart';
import 'package:edusistem_front/core/storage/token_storage.dart';
import 'package:edusistem_front/features/auth/domain/entities/user_entity.dart';
import 'package:edusistem_front/features/auth/domain/repositories/auth_repository.dart';
import 'package:edusistem_front/features/auth/presentation/providers/auth_provider.dart';
import 'package:edusistem_front/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthProvider authProvider;

  final user = UserEntity(
    id: 1,
    firstName: 'Ana',
    lastName: 'Pérez',
    email: 'ana@escuela.edu',
    active: true,
    roles: const ['TEACHER'],
    createdAt: DateTime(2026, 1, 1),
  );
  final tokens = AuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  setUp(() {
    repository = _MockAuthRepository();
    authProvider = AuthProvider(
      repository: repository,
      apiClient: ApiClient(onSessionExpired: () async {}),
    );
  });

  Widget buildTestable() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const MaterialApp(home: Scaffold(body: LoginForm())),
    );
  }

  testWidgets('shows a validation error for an invalid email', (tester) async {
    await tester.pumpWidget(buildTestable());

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa un email válido.'), findsOneWidget);
    verifyNever(() => repository.login(email: any(named: 'email'), password: any(named: 'password')));
  });

  testWidgets('calls AuthRepository.login and authenticates on valid credentials', (tester) async {
    when(
      () => repository.login(email: 'ana@escuela.edu', password: 'password123'),
    ).thenAnswer((_) async => (tokens, user));

    await tester.pumpWidget(buildTestable());

    await tester.enterText(find.byType(TextFormField).first, 'ana@escuela.edu');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    verify(() => repository.login(email: 'ana@escuela.edu', password: 'password123')).called(1);
    expect(authProvider.status, AuthStatus.authenticated);
    expect(authProvider.user?.fullName, 'Ana Pérez');
  });
}
