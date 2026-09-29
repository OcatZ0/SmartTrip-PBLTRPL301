import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/app_config.dart';

/// Thin Dio wrapper for the Laravel Sanctum REST API (PRD Section 11).
class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}
