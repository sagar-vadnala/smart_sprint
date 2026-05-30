sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String userName;
  final String email;

  AuthSuccess({required this.userName, required this.email});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}
