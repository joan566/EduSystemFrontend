import '../../../../core/storage/token_storage.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<(AuthTokens, UserEntity)> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<(AuthTokens, UserEntity)> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserEntity> getCurrentUser();

  Future<(AuthTokens, UserEntity)> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword(String email);

  Future<void> verifyCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
