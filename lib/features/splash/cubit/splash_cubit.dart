import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

sealed class SplashState {}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigateOnboarding extends SplashState {}

class SplashNavigateLogin extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initialize() async {
    emit(SplashLoading());
    await Future.delayed(const Duration(milliseconds: 2400));

    // Web users go straight to login — the swipe carousel is a mobile pattern.
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
