import 'auth_user.dart';

/// Result of a successful login: the user plus their Sanctum bearer token.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  final AuthUser user;
  final String token;
}
