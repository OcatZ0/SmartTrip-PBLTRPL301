import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:smarttrip_mobile/core/auth/auth_session.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/token_storage.dart';
import 'package:smarttrip_mobile/features/auth/data/auth_repository.dart';
import 'package:smarttrip_mobile/features/auth/data/google_auth_service.dart';

const testUser = AuthUser(
  usersId: 7,
  name: 'Budi',
  email: 'budi@example.com',
  role: 'user',
);

const testSession = AuthSession(user: testUser, token: 'token-123');

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({this.stored});

  /// What is "on disk" - survives across app launches in a real device.
  String? stored;
  String? _memory;
  bool? lastSavePersisted;

  @override
  Future<String?> read() async => _memory ?? stored;

  @override
  Future<void> save(String token, {bool persist = true}) async {
    _memory = token;
    lastSavePersisted = persist;
    stored = persist ? token : null;
  }

  @override
  Future<void> clear() async {
    _memory = null;
    stored = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.onLogin, this.onGoogleLogin});

  Future<AuthSession> Function(String email, String password)? onLogin;
  Future<AuthSession> Function(String idToken)? onGoogleLogin;

  final loginCalls = <({String email, String password})>[];

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    loginCalls.add((email: email, password: password));
    return onLogin?.call(email, password) ?? Future.value(testSession);
  }

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) {
    return onGoogleLogin?.call(idToken) ?? Future.value(testSession);
  }
}

class FakeGoogleAuthService implements GoogleAuthService {
  FakeGoogleAuthService({this.configured = true, this.idToken = 'google-id-token'});

  final bool configured;
  final String? idToken;

  @override
  bool get isConfigured => configured;

  @override
  Future<String?> getIdToken() async => idToken;
}

/// Serves canned responses so Dio-based code runs without a network.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
