/// Build-time configuration, provided via --dart-define.
///
/// Example:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  /// OAuth *web* client ID the backend verifies Google id_tokens against.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
