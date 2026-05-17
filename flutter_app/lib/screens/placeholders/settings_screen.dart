import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                _IconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  'Settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 20),
            _ProfileCard(
              name: authState.user?.displayName ?? 'Your Profile',
              subtitle: authState.user?.email ?? 'Tap to edit your profile',
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Account'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                    );
                  },
                ),
                _ToggleSettingsTile(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  prefKey: 'pref_notifications',
                ),
                _SettingsTile(
                  icon: Icons.favorite_border,
                  label: 'Health Goals',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Health Goals'),
                        content: const Text('Health goals settings coming soon.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'App Preferences'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  label: 'Appearance',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => SimpleDialog(
                        title: const Text('Choose theme'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () async {
                              final navigator = Navigator.of(dialogContext);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('pref_theme', 'light');
                              navigator.pop();
                            },
                            child: const Text('Light'),
                          ),
                          SimpleDialogOption(
                            onPressed: () async {
                              final navigator = Navigator.of(dialogContext);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('pref_theme', 'dark');
                              navigator.pop();
                            },
                            child: const Text('Dark'),
                          ),
                          SimpleDialogOption(
                            onPressed: () async {
                              final navigator = Navigator.of(dialogContext);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('pref_theme', 'system');
                              navigator.pop();
                            },
                            child: const Text('System'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.language,
                  label: 'Language',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Language'),
                        content: const Text('Language selection coming soon.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.security_outlined,
                  label: 'Privacy',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Privacy'),
                        content: const Text('Privacy options coming soon.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(authProvider.notifier).signOut();
                        },
                        child: Text(
                          'Sign Out',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }
}

class _ToggleSettingsTile extends StatefulWidget {
  const _ToggleSettingsTile({required this.icon, required this.label, required this.prefKey});

  final IconData icon;
  final String label;
  final String prefKey;

  @override
  State<_ToggleSettingsTile> createState() => _ToggleSettingsTileState();
}

class _ToggleSettingsTileState extends State<_ToggleSettingsTile> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _value = prefs.getBool(widget.prefKey) ?? true;
    });
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, value);
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(widget.icon, color: AppColors.onSurface),
      ),
      title: Text(
        widget.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Switch.adaptive(value: _value, onChanged: _toggle),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.onSurface),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
