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

  /// OAuth *web* client ID the backend verifies Google id_tokens against.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Place photos are stored on the API server and their URLs are built from
  /// the server's APP_URL, which in local development is `localhost` and
  /// unreachable from an emulator. Such URLs are pointed at the API host.
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final media = Uri.tryParse(url);
    if (media == null) return null;
    if (!media.hasScheme) return Uri.parse(apiBaseUrl).resolve(url).toString();

    final isLocalhost = media.host == 'localhost' || media.host == '127.0.0.1';
    if (!isLocalhost) return url;

    final api = Uri.parse(apiBaseUrl);
    return media.replace(host: api.host, port: api.port).toString();
  }
}
