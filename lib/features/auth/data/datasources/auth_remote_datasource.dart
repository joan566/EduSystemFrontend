import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  /// Creates an unverified account; no session is returned until the email
  /// is verified and the user logs in.
  Future<UserEntity> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return UserModel.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    await _client.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resendVerification(String email) async {
    await _client.post(ApiEndpoints.resendVerification, data: {'email': email});
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }

  Future<UserEntity> me() async {
    final response = await _client.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) async {
    await _client.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> verifyCode({required String email, required String code}) async {
    await _client.post(
      ApiEndpoints.verifyCode,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> deleteAccount(String password) =>
      _client.delete(ApiEndpoints.account, data: {'password': password});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }
}
