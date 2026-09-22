import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import 'user_model.dart';

/// Maps the backend's `AuthResponse` JSON into the two pieces the app
/// cares about: the token pair and the authenticated user.
class AuthResponseModel {
  const AuthResponseModel({required this.tokens, required this.user});

  final AuthTokens tokens;
  final UserEntity user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expiresIn'] as int? ?? 3600;
    return AuthResponseModel(
      tokens: AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      ),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
