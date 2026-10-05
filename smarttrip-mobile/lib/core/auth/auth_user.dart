/// Authenticated user as returned by `POST /api/auth/login` and `GET /api/user`.
class AuthUser {
  const AuthUser({
    required this.usersId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usersId: json['users_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
    );
  }

  final int usersId;
  final String name;
  final String email;
  final String role;
}
