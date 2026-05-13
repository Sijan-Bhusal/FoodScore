import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/tokens.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();
  String _bloodType = 'O+';
  bool _loading = true;

  static const _kName = 'profile_name';
  static const _kAge = 'profile_age';
  static const _kWeight = 'profile_weight';
  static const _kHeight = 'profile_height';
  static const _kBlood = 'profile_blood';
  static const _kAllergies = 'profile_allergies';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nameController.text = prefs.getString(_kName) ?? '';
      final age = prefs.getInt(_kAge);
      if (age != null) _ageController.text = age.toString();
      final weight = prefs.getDouble(_kWeight);
      if (weight != null) _weightController.text = weight.toString();
      final height = prefs.getDouble(_kHeight);
      if (height != null) _heightController.text = height.toString();
      _bloodType = prefs.getString(_kBlood) ?? _bloodType;
      _allergiesController.text = prefs.getString(_kAllergies) ?? '';
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDAF3E5), Color(0xFFF9F7F0)],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView(
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
                            'Set Up Profile',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tell us about you',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InputField(
                                      controller: _ageController,
                                      label: 'Age',
                                      hint: 'Years',
                                      icon: Icons.cake_outlined,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InputField(
                                      controller: _heightController,
                                      label: 'Height',
                                      hint: 'cm',
                                      icon: Icons.height,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InputField(
                                      controller: _weightController,
                                      label: 'Weight',
                                      hint: 'kg',
                                      icon: Icons.monitor_weight_outlined,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DropdownField(
                                      label: 'Blood Type',
                                      value: _bloodType,
                                      items: const [
                                        'O+',
                                        'O-',
                                        'A+',
                                        'A-',
                                        'B+',
                                        'B-',
                                        'AB+',
                                        'AB-',
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _bloodType = value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _allergiesController,
                                label: 'Allergies',
                                hint: 'List any allergies',
                                icon: Icons.warning_amber_outlined,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () async {
                                  if (!(_formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  try {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      _kName,
                                      _nameController.text,
                                    );
                                    await prefs.setInt(
                                      _kAge,
                                      int.tryParse(_ageController.text) ?? 0,
                                    );
                                    await prefs.setDouble(
                                      _kWeight,
                                      double.tryParse(_weightController.text) ??
                                          0.0,
                                    );
                                    await prefs.setDouble(
                                      _kHeight,
                                      double.tryParse(_heightController.text) ??
                                          0.0,
                                    );
                                    await prefs.setString(_kBlood, _bloodType);
                                    await prefs.setString(
                                      _kAllergies,
                                      _allergiesController.text,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile saved.'),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;
                                    // ignore: use_build_context_synchronously
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Save failed.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Save Profile'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
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
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if ((value ?? '').isEmpty && label == 'Full Name') {
          return 'Enter your name.';
        }
        return null;
      },
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
    );
  }
}
