/// Authenticated user (teacher/admin). Domain entity — no JSON knowledge.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.active,
    required this.roles,
    required this.createdAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool active;
  final List<String> roles;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  bool get isAdmin => roles.contains('ADMIN');

  UserEntity copyWith({String? firstName, String? lastName}) => UserEntity(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email,
    active: active,
    roles: roles,
    createdAt: createdAt,
  );
}
