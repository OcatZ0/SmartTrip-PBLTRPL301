import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

/// Thrown when the build has no `GOOGLE_SERVER_CLIENT_ID`, so Google
/// Sign-In cannot produce an id_token the backend would accept.
class GoogleNotConfiguredException implements Exception {
  const GoogleNotConfiguredException();
}

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              serverClientId: AppConfig.googleServerClientId.isEmpty
                  ? null
                  : AppConfig.googleServerClientId,
            );

  final GoogleSignIn _googleSignIn;

  bool get isConfigured => AppConfig.googleServerClientId.isNotEmpty;

  /// Returns the Google id_token, or `null` if the user dismissed the picker.
  Future<String?> getIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    return authentication.idToken;
  }
}

final googleAuthServiceProvider =
    Provider<GoogleAuthService>((ref) => GoogleAuthService());
