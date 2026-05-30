sealed class AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  AuthLoginSubmitted({required this.email, required this.password});
}

class AuthSignupSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;

  AuthSignupSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}
