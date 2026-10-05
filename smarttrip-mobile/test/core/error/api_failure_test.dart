import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';

DioException _exception({int? status, Object? data}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('no response maps to NetworkFailure', () {
    expect(
      ApiFailure.fromDioException(_exception()),
      isA<NetworkFailure>(),
    );
  });

  test('401 maps to UnauthorizedFailure with the server message', () {
    final failure = ApiFailure.fromDioException(
      _exception(status: 401, data: {'message': 'Unauthenticated.'}),
    );

    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.message, 'Unauthenticated.');
  });

  test('422 maps to ValidationFailure with per-field errors', () {
    final failure = ApiFailure.fromDioException(
      _exception(
        status: 422,
        data: {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['Email atau kata sandi salah.'],
            'password': ['a', 'b'],
          },
        },
      ),
    ) as ValidationFailure;

    expect(failure.firstError('email'), 'Email atau kata sandi salah.');
    expect(failure.fieldErrors['password'], ['a', 'b']);
    expect(failure.firstError('unknown'), isNull);
  });

  test('422 without an errors object yields no field errors', () {
    final failure = ApiFailure.fromDioException(
      _exception(status: 422, data: {'message': 'oops'}),
    ) as ValidationFailure;

    expect(failure.fieldErrors, isEmpty);
    expect(failure.message, 'oops');
  });

  test('other statuses map to ServerFailure carrying the status code', () {
    final failure = ApiFailure.fromDioException(
      _exception(status: 500, data: 'Server Error'),
    ) as ServerFailure;

    expect(failure.statusCode, 500);
    expect(failure.message, isNull);
  });
}
