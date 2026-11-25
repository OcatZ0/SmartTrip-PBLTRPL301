import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/api/api_client.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';

import '../../helpers/test_doubles.dart';

ProviderContainer _container(
  InMemoryTokenStorage tokenStorage,
  HttpClientAdapter adapter,
) {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokenStorage),
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          tokenStorage: tokenStorage,
          dio: Dio()..httpClientAdapter = adapter,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('no stored token means logged out, without any network call', () async {
    final adapter = FakeHttpClientAdapter((_) => jsonResponse({}, 500));
    final container = _container(InMemoryTokenStorage(), adapter);

    final user = await container.read(sessionControllerProvider.future);

    expect(user, isNull);
    expect(adapter.requests, isEmpty);
  });

  test('a stored token is restored into the user via GET /user', () async {
    final adapter = FakeHttpClientAdapter(
      (_) => jsonResponse({
        'users_id': 7,
        'name': 'Budi',
        'email': 'budi@example.com',
        'role': 'user',
      }, 200),
    );
    final container = _container(InMemoryTokenStorage(stored: 'abc'), adapter);

    final user = await container.read(sessionControllerProvider.future);

    expect(user?.email, 'budi@example.com');
    expect(adapter.requests.single.path, '/user');
  });

  test('an expired token (401) logs out and clears the stored token', () async {
    final tokenStorage = InMemoryTokenStorage(stored: 'old');
    final adapter = FakeHttpClientAdapter(
      (_) => jsonResponse({'message': 'Unauthenticated.'}, 401),
    );
    final container = _container(tokenStorage, adapter);

    final user = await container.read(sessionControllerProvider.future);

    expect(user, isNull);
    expect(tokenStorage.stored, isNull);
  });

  test('a network failure logs out for now but keeps the stored token', () async {
    final tokenStorage = InMemoryTokenStorage(stored: 'abc');
    final adapter = FakeHttpClientAdapter(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );
    final container = _container(tokenStorage, adapter);

    final user = await container.read(sessionControllerProvider.future);

    expect(user, isNull);
    expect(tokenStorage.stored, 'abc');
  });

  test('signIn(remember: false) keeps the token in memory only', () async {
    final tokenStorage = InMemoryTokenStorage();
    final container = _container(
      tokenStorage,
      FakeHttpClientAdapter((_) => jsonResponse({}, 500)),
    );
    await container.read(sessionControllerProvider.future);

    await container
        .read(sessionControllerProvider.notifier)
        .signIn(testSession, remember: false);

    expect(container.read(sessionControllerProvider).value, testUser);
    expect(await tokenStorage.read(), 'token-123');
    expect(tokenStorage.stored, isNull);
  });

  test('signIn(remember: true) persists the token', () async {
    final tokenStorage = InMemoryTokenStorage();
    final container = _container(
      tokenStorage,
      FakeHttpClientAdapter((_) => jsonResponse({}, 500)),
    );
    await container.read(sessionControllerProvider.future);

    await container
        .read(sessionControllerProvider.notifier)
        .signIn(testSession, remember: true);

    expect(tokenStorage.stored, 'token-123');
  });

  test('handleUnauthorized clears the session and the token', () async {
    final tokenStorage = InMemoryTokenStorage();
    final container = _container(
      tokenStorage,
      FakeHttpClientAdapter((_) => jsonResponse({}, 500)),
    );
    await container.read(sessionControllerProvider.future);
    await container
        .read(sessionControllerProvider.notifier)
        .signIn(testSession, remember: true);

    await container.read(sessionControllerProvider.notifier).handleUnauthorized();

    expect(container.read(sessionControllerProvider).value, isNull);
    expect(tokenStorage.stored, isNull);
  });

  test('signOut leaves at once and revokes the token in the background', () async {
    final tokenStorage = InMemoryTokenStorage();
    final pending = Completer<ResponseBody>();
    final adapter = _PendingAdapter(pending.future);
    final container = _container(tokenStorage, adapter);
    await container.read(sessionControllerProvider.future);
    await container.read(sessionControllerProvider.notifier).signIn(testSession, remember: true);

    // The server never answers, yet the session is already gone.
    await container.read(sessionControllerProvider.notifier).signOut();

    expect(container.read(sessionControllerProvider).value, isNull);
    expect(tokenStorage.stored, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(adapter.requests.single.path, '/auth/logout');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer token-123');
  });
}

class _PendingAdapter implements HttpClientAdapter {
  _PendingAdapter(this.answer);

  final Future<ResponseBody> answer;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    return answer;
  }

  @override
  void close({bool force = false}) {}
}
