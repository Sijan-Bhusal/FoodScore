import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final bool isComplete;

  const OnboardingState({this.isComplete = false});
}

final preloadedOnboardingCompleteProvider = Provider<bool>((ref) => false);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final completed = ref.watch(preloadedOnboardingCompleteProvider);
    return OnboardingState(isComplete: completed);
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    state = const OnboardingState(isComplete: true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    state = const OnboardingState(isComplete: false);
  }

  Future<void> saveGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('health_goals', goals);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
