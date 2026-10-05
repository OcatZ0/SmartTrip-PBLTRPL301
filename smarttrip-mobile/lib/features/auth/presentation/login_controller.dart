import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../data/auth_repository.dart';
import '../data/google_auth_service.dart';

/// Drives the login form: the state is the in-flight/failed result of the
/// last submit. Success flows through [SessionController], which the router
/// observes to leave the login screen.
class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(session, remember: remember);
    });
  }

  Future<void> loginWithGoogle({required bool remember}) async {
    final google = ref.read(googleAuthServiceProvider);
    if (!google.isConfigured) {
      state = AsyncError(
        const GoogleNotConfiguredException(),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final idToken = await google.getIdToken();
      if (idToken == null) return;

      final session = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(idToken: idToken);
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(session, remember: remember);
    });
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
  LoginController.new,
);
