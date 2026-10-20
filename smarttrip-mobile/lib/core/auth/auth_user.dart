/// Authenticated user as returned by `POST /api/auth/login` and `GET /api/user`.
class AuthUser {
  const AuthUser({
    required this.usersId,
    required this.name,
    required this.email,
    required this.role,
    this.hasPassword = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usersId: json['users_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      hasPassword: json['has_password'] as bool? ?? true,
    );
  }

  final int usersId;
  final String name;
  final String email;
  final String role;

  /// False for a Google-only account, which has no password to confirm yet.
  final bool hasPassword;

  AuthUser withPassword() => AuthUser(usersId: usersId, name: name, email: email, role: role);
}
