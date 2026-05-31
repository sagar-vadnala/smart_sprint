import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT access token so the user stays logged in across launches.
///
/// Note: SharedPreferences is fine for a learning project. For production,
/// graduate to `flutter_secure_storage` (Keychain / Keystore) so the token
/// isn't readable in plain prefs.
class TokenStore {
  static const _key = 'auth_token';

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
