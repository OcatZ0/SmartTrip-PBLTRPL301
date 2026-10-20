import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:smarttrip_mobile/core/auth/auth_session.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/token_storage.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';
import 'package:smarttrip_mobile/services/google_auth_service.dart';

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

class FakeAuthService implements AuthService {
  FakeAuthService({this.onLogin, this.onGoogleLogin, this.onRegister});

  Future<AuthSession> Function(String email, String password)? onLogin;
  Future<AuthSession> Function(String idToken)? onGoogleLogin;
  Future<String> Function(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  )? onRegister;

  final loginCalls = <({String email, String password})>[];
  final registerCalls = <({
    String name,
    String email,
    String password,
    String passwordConfirmation,
  })>[];

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

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    registerCalls.add((
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ));
    return onRegister?.call(name, email, password, passwordConfirmation) ??
        Future.value('Silakan cek email Anda untuk verifikasi akun.');
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

/// Widget tests draw unknown fonts as 1em-wide boxes, which makes text far
/// wider than on a phone. Layout tests load the real app font instead.
Future<void> loadAppFont() async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
  await loader.load();
}
