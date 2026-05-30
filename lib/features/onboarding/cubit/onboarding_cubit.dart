import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final int currentPage;
  final bool isComplete;

  const OnboardingState({required this.currentPage, this.isComplete = false});

  OnboardingState copyWith({int? currentPage, bool? isComplete}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState(currentPage: 0));

  void nextPage() {
    if (state.currentPage < 2) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void goToPage(int page) {
    emit(state.copyWith(currentPage: page));
  }

  Future<void> skip() async {
    await _markComplete();
    emit(state.copyWith(isComplete: true));
  }

  Future<void> finish() async {
    await _markComplete();
    emit(state.copyWith(isComplete: true));
  }

  Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }
}
