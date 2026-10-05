import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the Sanctum bearer token (PRD Section 13 - Auth token). The token is
/// always kept in memory for the running session; it is only written to
/// secure storage when the user chose "Ingat Saya".
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _memoryToken;

  Future<String?> read() async =>
      _memoryToken ?? await _storage.read(key: _tokenKey);

  Future<void> save(String token, {bool persist = true}) async {
    _memoryToken = token;
    if (persist) {
      await _storage.write(key: _tokenKey, value: token);
    } else {
      await _storage.delete(key: _tokenKey);
    }
  }

  Future<void> clear() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}
