import 'package:flutter/foundation.dart';
import 'package:smart_sprint/core/auth/token_store.dart';

/// Single source of truth for "is a user signed in".
///
/// The router reads [isSignedIn] synchronously to decide redirects and listens
/// to this (`refreshListenable`) to re-run them the instant auth changes. Keep
/// the token (persistence) and this flag (in-memory truth) in lockstep:
///   • sign-in flows  → [TokenStore.save] then [signedIn]
///   • sign-out / 401 → [TokenStore.clear] then [signedOut]
class AuthSession extends ChangeNotifier {
  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  /// Seed the flag from the persisted token. Call once before the app builds.
  Future<void> init() async {
    final token = await TokenStore().read();
    _set(token != null && token.isNotEmpty);
  }

  void signedIn() => _set(true);
  void signedOut() => _set(false);

  void _set(bool value) {
    if (_signedIn == value) return;
    _signedIn = value;
    notifyListeners();
  }
}

/// App-wide instance. Seeded in `main()`.
final authSession = AuthSession();
