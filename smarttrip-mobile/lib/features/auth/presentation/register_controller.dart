import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Drives the registration form: the state is the in-flight or completed result
/// of the last registration submission (returning the success message from server).
class RegisterController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).register(
            name: name.trim(),
            email: email.trim(),
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
    });
  }
}

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, String?>(
  RegisterController.new,
);
