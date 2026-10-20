import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/providers.dart';
import '../error/api_failure.dart';
import 'auth_session.dart';
import 'auth_user.dart';

/// Single source of truth for "who is logged in". The router redirects off
/// this state; `null` data means logged out.
class SessionController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.read();
    if (token == null) return null;

    try {
      final response = await ref.read(apiClientProvider).dio.get<Map<String, dynamic>>(
            '/user',
            options: Options(extra: {ApiClient.skipUnauthorizedHandler: true}),
          );
      return AuthUser.fromJson(response.data!);
    } on DioException catch (error) {
      // Only an expired/revoked token clears the stored login. A network
      // failure keeps it so the next launch can retry.
      if (ApiFailure.fromDioException(error) is UnauthorizedFailure) {
        await tokenStorage.clear();
      }
      return null;
    }
  }

  Future<void> signIn(AuthSession session, {required bool remember}) async {
    await ref.read(tokenStorageProvider).save(session.token, persist: remember);
    state = AsyncData(session.user);
  }

  /// After a Google-only account sets its first password.
  void markPasswordSet() {
    final user = state.valueOrNull;
    if (user != null) state = AsyncData(user.withPassword());
  }

  /// Revokes the token on the server when it can; the local login is
  /// cleared either way, so an offline phone still logs out.
  Future<void> signOut() async {
    try {
      await ref.read(apiClientProvider).dio.post<Map<String, dynamic>>(
            '/auth/logout',
            options: Options(extra: {ApiClient.skipUnauthorizedHandler: true}),
          );
    } on DioException {
      // Nothing to undo: the token is dropped below.
    }
    await handleUnauthorized();
  }

  Future<void> handleUnauthorized() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, AuthUser?>(SessionController.new);
