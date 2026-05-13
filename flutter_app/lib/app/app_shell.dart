import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation.dart';

import '../screens/home/home_screen.dart';
import '../screens/placeholders/history_screen.dart';
import '../screens/placeholders/settings_screen.dart';
import 'tokens.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screens = const [HomeScreen(), HistoryScreen(), SettingsScreen()];

    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: navIndex,
        builder: (context, index, _) =>
            IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navIndex.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home,
            isActive: currentIndex == 0,
            onTap: () => navIndex.value = 0,
          ),
          _NavItem(
            label: 'History',
            icon: Icons.history,
            isActive: currentIndex == 1,
            onTap: () => navIndex.value = 1,
          ),
          _NavItem(
            label: 'Settings',
            icon: Icons.settings,
            isActive: currentIndex == 2,
            onTap: () => navIndex.value = 2,
          ),
        ],
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
    final color = isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    final background = isActive
        ? AppColors.primaryContainer
        : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            if (isActive) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
