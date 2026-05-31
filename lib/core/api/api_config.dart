/// Base URL of the SmartSprint backend.
///
/// Injected at build/run time so there is **no hard-coded localhost** — point
/// the app at your deployed API with:
///
///   flutter run --dart-define=API_BASE_URL=https://your-api.onrender.com
///
/// The default below is only a dev fallback (local FastAPI). On web `localhost`
/// works from a browser on the same machine; on a physical device use your
/// machine's LAN IP or, better, the deployed URL.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smartsprint-api.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 20);

  // Render free tier can cold-start ~50s — give responses room to arrive.
  static const Duration receiveTimeout = Duration(seconds: 60);
}
