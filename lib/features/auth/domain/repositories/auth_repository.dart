import '../../../../core/storage/token_storage.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Creates an unverified account (no session): the user must verify the
  /// email with [verifyEmail] and then [login].
  Future<UserEntity> register({
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

  Future<void> verifyEmail({required String email, required String code});

  /// Sends a new verification code; the previous one stops working.
  Future<void> resendVerification(String email);

  Future<void> forgotPassword(String email);

  Future<void> verifyCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Permanently deletes the account and all of its data, then clears the
  /// stored tokens (the backend revokes them immediately).
  Future<void> deleteAccount(String password);
}
