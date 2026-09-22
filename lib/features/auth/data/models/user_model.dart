import '../../domain/entities/user_entity.dart';

/// Maps the backend's `UserResponse` JSON to [UserEntity].
class UserModel {
  static UserEntity fromJson(Map<String, dynamic> json) => UserEntity(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    active: json['active'] as bool? ?? true,
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
