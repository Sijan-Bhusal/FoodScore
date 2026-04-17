import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home/home_screen.dart';
import '../screens/placeholders/history_screen.dart';
import '../screens/placeholders/insights_screen.dart';
import '../screens/placeholders/settings_screen.dart';
import 'tokens.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    final screens = const [
      HomeScreen(),
      HistoryScreen(),
      InsightsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.06),
                blurRadius: 32,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home,
                isActive: currentIndex == 0,
                onTap: () => ref.read(navIndexProvider.notifier).state = 0,
              ),
              _NavItem(
                label: 'History',
                icon: Icons.history,
                isActive: currentIndex == 1,
                onTap: () => ref.read(navIndexProvider.notifier).state = 1,
              ),
              _NavItem(
                label: 'Insights',
                icon: Icons.analytics,
                isActive: currentIndex == 2,
                onTap: () => ref.read(navIndexProvider.notifier).state = 2,
              ),
              _NavItem(
                label: 'Settings',
                icon: Icons.settings,
                isActive: currentIndex == 3,
                onTap: () => ref.read(navIndexProvider.notifier).state = 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.onSurfaceVariant;
    final background = isActive
        ? AppColors.primaryFixed.withOpacity(0.7)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
