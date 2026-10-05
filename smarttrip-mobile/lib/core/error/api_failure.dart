import 'package:dio/dio.dart';

/// Typed failure for any call to the Laravel REST API. Repositories throw
/// these; controllers surface them through `AsyncValue.guard`.
sealed class ApiFailure implements Exception {
  const ApiFailure([this.message]);

  final String? message;

  factory ApiFailure.fromDioException(DioException exception) {
    final response = exception.response;
    if (response == null) {
      return const NetworkFailure();
    }

    final data = response.data;
    final serverMessage = data is Map ? data['message'] as String? : null;

    return switch (response.statusCode) {
      401 => UnauthorizedFailure(serverMessage),
      422 => ValidationFailure(serverMessage, _parseFieldErrors(data)),
      final status => ServerFailure(status, serverMessage),
    };
  }

  static Map<String, List<String>> _parseFieldErrors(Object? data) {
    final errors = data is Map ? data['errors'] : null;
    if (errors is! Map) return const {};

    return {
      for (final entry in errors.entries)
        entry.key.toString(): [
          if (entry.value is List)
            for (final message in entry.value as List) message.toString(),
        ],
    };
  }
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure();
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure([super.message]);
}

/// HTTP 422 with Laravel's `{message, errors: {field: [..]}}` body.
class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message, this.fieldErrors);

  final Map<String, List<String>> fieldErrors;

  String? firstError(String field) {
    final messages = fieldErrors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }
}

class ServerFailure extends ApiFailure {
  const ServerFailure(this.statusCode, [super.message]);

  final int? statusCode;
}
