import 'package:smart_sprint/core/api/api_client.dart';
import 'package:smart_sprint/core/auth/auth_session.dart';
import 'package:smart_sprint/core/auth/token_store.dart';
import 'package:smart_sprint/features/auth/data/auth_user.dart';

/// Talks to the backend's `/auth/*` endpoints and owns the access token.
///
/// On a successful signup/login it persists the token via [TokenStore]; the
/// [ApiClient] interceptor then attaches it to every subsequent request.
class AuthRepository {
  final ApiClient _api;
  final TokenStore _tokenStore;

  AuthRepository({ApiClient? api, TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _api = api ?? ApiClient(tokenStore: tokenStore);

  /// Throws [ApiException] on failure (already carries a readable message).
  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/auth/signup',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _persistAndParse(body);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _persistAndParse(body);
  }

  /// Exchange a Google credential for our session.
  /// Mobile sends [idToken]; web sends [accessToken] (popup flow limitation).
  Future<AuthUser> googleLogin({String? idToken, String? accessToken}) async {
    final body = await _api.post('/auth/google', data: {
      'id_token': idToken,
      'access_token': accessToken,
    });
    return _persistAndParse(body);
  }

  /// Returns the user for a stored token, or null if there's no valid session.
  Future<AuthUser?> currentUser() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    try {
      final body = await _api.get('/auth/me');
      return AuthUser.fromJson(body);
    } on ApiException {
      // Token expired/invalid — clear it so we don't loop.
      await _tokenStore.clear();
      authSession.signedOut();
      return null;
    }
  }

  Future<bool> hasToken() async {
    final token = await _tokenStore.read();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    authSession.signedOut();
  }

  Future<AuthUser> _persistAndParse(Map<String, dynamic> body) async {
    final token = body['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _tokenStore.save(token);
      authSession.signedIn();
    }
    final user = body['user'] as Map<String, dynamic>;
    return AuthUser.fromJson(user);
  }
}
