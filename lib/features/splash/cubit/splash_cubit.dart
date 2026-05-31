import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sprint/features/auth/data/auth_repository.dart';

sealed class SplashState {}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigateOnboarding extends SplashState {}

class SplashNavigateLogin extends SplashState {}

class SplashNavigateHome extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _auth;

  SplashCubit({AuthRepository? auth})
    : _auth = auth ?? AuthRepository(),
      super(SplashInitial());

  Future<void> initialize() async {
    emit(SplashLoading());
    await Future.delayed(const Duration(milliseconds: 2400));

    // Already logged in? Skip straight to the app. (We check the locally stored
    // token for an instant decision; its real validity is enforced lazily on
    // the first authenticated request.)
    if (await _auth.hasToken()) {
      emit(SplashNavigateHome());
      return;
    }

    // Web users skip the onboarding carousel (a mobile pattern).
    if (kIsWeb) {
      emit(SplashNavigateLogin());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    if (seenOnboarding) {
      emit(SplashNavigateLogin());
    } else {
      emit(SplashNavigateOnboarding());
    }
  }
}
