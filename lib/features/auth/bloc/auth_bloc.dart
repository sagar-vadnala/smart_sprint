import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_sprint/core/api/api_client.dart';
import 'package:smart_sprint/core/api/api_config.dart';
import 'package:smart_sprint/features/auth/data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc({AuthRepository? repository})
    : _repo = repository ?? AuthRepository(),
      super(AuthInitial()) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignupSubmitted>(_onSignupSubmitted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty || event.password.isEmpty) {
      emit(AuthFailure('Please fill in all fields.'));
      return;
    }
    if (!_isValidEmail(email)) {
      emit(AuthFailure('Enter a valid email address.'));
      return;
    }

    emit(AuthLoading());
    try {
      final user = await _repo.login(email: email, password: event.password);
      emit(AuthSuccess(user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  Future<void> _onSignupSubmitted(
    AuthSignupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final name = event.name.trim();
    final email = event.email.trim();
    if (name.isEmpty || email.isEmpty || event.password.isEmpty) {
      emit(AuthFailure('Please fill in all fields.'));
      return;
    }
    if (!_isValidEmail(email)) {
      emit(AuthFailure('Enter a valid email address.'));
      return;
    }
    if (event.password.length < 8) {
      emit(AuthFailure('Password must be at least 8 characters.'));
      return;
    }

    emit(AuthLoading());
    try {
      final user = await _repo.signup(
        name: name,
        email: email,
        password: event.password,
      );
      emit(AuthSuccess(user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (ApiConfig.googleClientId.isEmpty) {
      emit(
        AuthFailure(
          'Google sign-in is not configured for this build. '
          'Use email & password.',
        ),
      );
      return;
    }

    try {
      // On web we pass the client id directly; on mobile we use it as the
      // serverClientId so the returned ID token's audience matches what the
      // backend verifies against.
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: kIsWeb ? ApiConfig.googleClientId : null,
        serverClientId: kIsWeb ? null : ApiConfig.googleClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the chooser.
        emit(AuthInitial());
        return;
      }

      emit(AuthLoading());
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(AuthFailure('Google did not return a valid token. Try again.'));
        return;
      }

      final user = await _repo.googleLogin(idToken);
      emit(AuthSuccess(user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(AuthFailure('Google sign-in failed. Please try again.'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.logout();
    emit(AuthInitial());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }
}
