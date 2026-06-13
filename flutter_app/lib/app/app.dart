import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import 'app_shell.dart';
import 'theme.dart';

class FoodScoreApp extends StatelessWidget {
  const FoodScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodScore',
      theme: AppTheme.light(),
      home: const AppEntry(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final auth = ref.watch(authProvider);

    if (!onboarding.isComplete) {
      return const OnboardingScreen();
    }

    if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.status == AuthStatus.guest ||
        auth.status == AuthStatus.authenticated) {
      return const AppShell();
    }

    return const AuthScreen();
  }
}
