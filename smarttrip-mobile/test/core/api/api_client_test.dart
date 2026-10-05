import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/api/api_client.dart';

import '../../helpers/test_doubles.dart';

void main() {
  late InMemoryTokenStorage tokenStorage;
  late FakeHttpClientAdapter adapter;
  late int unauthorizedCalls;
  late ApiClient client;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    unauthorizedCalls = 0;
    adapter = FakeHttpClientAdapter(
      (options) => jsonResponse({'message': 'Unauthenticated.'}, 401),
    );
    client = ApiClient(
      tokenStorage: tokenStorage,
      onUnauthorized: () => unauthorizedCalls++,
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  test('sends the bearer token when one is stored', () async {
    await tokenStorage.save('abc');

    await client.dio.get<void>('/user').catchError((_) => Response<void>(requestOptions: RequestOptions()));

    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('a 401 on an authenticated request triggers onUnauthorized', () async {
    await tokenStorage.save('abc');

    await expectLater(client.dio.get<void>('/user'), throwsA(isA<DioException>()));

    expect(unauthorizedCalls, 1);
  });

  test('a 401 without a token (e.g. wrong login) does not trigger it', () async {
    await expectLater(client.dio.post<void>('/auth/login'), throwsA(isA<DioException>()));

    expect(unauthorizedCalls, 0);
  });

  test('skipUnauthorizedHandler suppresses the callback', () async {
    await tokenStorage.save('abc');

    await expectLater(
      client.dio.get<void>(
        '/user',
        options: Options(extra: {ApiClient.skipUnauthorizedHandler: true}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(unauthorizedCalls, 0);
  });
}
