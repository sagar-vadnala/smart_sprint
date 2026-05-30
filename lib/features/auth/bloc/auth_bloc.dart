import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignupSubmitted>(_onSignupSubmitted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1200));

    if (event.email.trim().isEmpty || event.password.isEmpty) {
      emit(AuthFailure('Please fill in all fields.'));
      return;
    }
    if (!_isValidEmail(event.email)) {
      emit(AuthFailure('Enter a valid email address.'));
      return;
    }
    if (event.password.length < 6) {
      emit(AuthFailure('Password must be at least 6 characters.'));
      return;
    }

    final name = event.email.split('@').first;
    emit(AuthSuccess(
      userName: _capitalize(name),
      email: event.email.trim(),
    ));
  }

  Future<void> _onSignupSubmitted(
    AuthSignupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1400));

    if (event.name.trim().isEmpty ||
        event.email.trim().isEmpty ||
        event.password.isEmpty) {
      emit(AuthFailure('Please fill in all fields.'));
      return;
    }
    if (!_isValidEmail(event.email)) {
      emit(AuthFailure('Enter a valid email address.'));
      return;
    }
    if (event.password.length < 8) {
      emit(AuthFailure('Password must be at least 8 characters.'));
      return;
    }

    emit(AuthSuccess(
      userName: _capitalize(event.name.trim()),
      email: event.email.trim(),
    ));
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1000));
    // Stub — wire up google_sign_in package when needed
    emit(AuthSuccess(userName: 'Google User', email: 'user@gmail.com'));
  }

  void _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
