import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose how NearMeU looks on this device.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.settings_suggest_rounded,
                title: 'System default',
                subtitle: 'Follow your phone light or dark setting',
                value: AppThemePreference.system,
                selected: controller.preference,
              ),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                title: 'Light',
                subtitle: 'Use the bright NearMeU theme',
                value: AppThemePreference.light,
                selected: controller.preference,
              ),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                title: 'Dark',
                subtitle: 'Use the original dark NearMeU theme',
                value: AppThemePreference.dark,
                selected: controller.preference,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemePreference value;
  final AppThemePreference selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == selected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<AppThemePreference>(
        value: value,
        groupValue: selected,
        onChanged: (preference) {
          if (preference != null) {
            ThemeController.instance.setPreference(preference);
          }
        },
        secondary: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
