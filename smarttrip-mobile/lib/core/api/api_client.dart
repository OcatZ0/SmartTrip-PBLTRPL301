import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/app_config.dart';

/// Thin Dio wrapper for the Laravel Sanctum REST API (PRD Section 11).
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    void Function()? onUnauthorized,
    Dio? dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                headers: {'Accept': 'application/json'},
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final request = error.requestOptions;
          final hadToken = request.headers.containsKey('Authorization');
          final skip = request.extra[skipUnauthorizedHandler] == true;
          if (error.response?.statusCode == 401 && hadToken && !skip) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Set in `Options.extra` for a request that handles its own 401 (e.g. the
  /// session restore call), so the global handler does not fire as well.
  static const skipUnauthorizedHandler = 'skipUnauthorizedHandler';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}
