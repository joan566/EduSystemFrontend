import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required ApiClient apiClient,
  }) : _remote = remoteDataSource,
       _apiClient = apiClient;

  final AuthRemoteDataSource _remote;
  final ApiClient _apiClient;

  @override
  Future<(AuthTokens, UserEntity)> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final result = await _remote.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    await _apiClient.setSession(result.tokens);
    return (result.tokens, result.user);
  }

  @override
  Future<(AuthTokens, UserEntity)> login({
    required String email,
    required String password,
  }) async {
    final result = await _remote.login(email: email, password: password);
    await _apiClient.setSession(result.tokens);
    return (result.tokens, result.user);
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _apiClient.clearSession();
    }
  }

  @override
  Future<UserEntity> getCurrentUser() => _remote.me();

  @override
  Future<(AuthTokens, UserEntity)> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _apiClient.setSession(result.tokens);
    return (result.tokens, result.user);
  }

  @override
  Future<void> forgotPassword(String email) => _remote.forgotPassword(email);

  @override
  Future<void> verifyCode({required String email, required String code}) =>
      _remote.verifyCode(email: email, code: code);

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _remote.resetPassword(email: email, code: code, newPassword: newPassword);

  @override
  Future<void> deleteAccount(String password) async {
    await _remote.deleteAccount(password);
    await _apiClient.clearSession();
  }
}
