/// Authenticated user as returned by `POST /api/auth/login` and `GET /api/user`.
class AuthUser {
  const AuthUser({
    required this.usersId,
    required this.name,
    required this.email,
    required this.role,
    this.hasPassword = true,
    this.hasInterests = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usersId: json['users_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      hasPassword: json['has_password'] as bool? ?? true,
      hasInterests: json['has_interests'] as bool? ?? true,
    );
  }

  final int usersId;
  final String name;
  final String email;
  final String role;

  /// False for a Google-only account, which has no password to confirm yet.
  final bool hasPassword;

  /// False until the user picks default interests; the router keeps them on
  /// the Pilih Minat screen until then (F009). Missing in the JSON counts as
  /// picked, so an older server never traps the user there.
  final bool hasInterests;

  AuthUser withPassword() => _copy(hasPassword: true);

  AuthUser withInterests() => _copy(hasInterests: true);

  AuthUser _copy({bool? hasPassword, bool? hasInterests}) => AuthUser(
        usersId: usersId,
        name: name,
        email: email,
        role: role,
        hasPassword: hasPassword ?? this.hasPassword,
        hasInterests: hasInterests ?? this.hasInterests,
      );
}
