import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/providers.dart';
import '../core/auth/auth_session.dart';
import '../core/error/api_failure.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _authenticate('/auth/login', {'email': email, 'password': password});
  }

  Future<AuthSession> loginWithGoogle({required String idToken}) {
    return _authenticate('/auth/google', {'id_token': idToken});
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return (response.data?['message'] as String?) ?? '';
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<AuthSession> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response =
          await _apiClient.dio.post<Map<String, dynamic>>(path, data: body);
      return AuthSession.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});
