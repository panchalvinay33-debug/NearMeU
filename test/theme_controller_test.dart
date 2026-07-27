import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system theme when no preference is saved', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.instance.load();

    expect(ThemeController.instance.preference, AppThemePreference.system);
    expect(ThemeController.instance.themeMode, ThemeMode.system);
  });

  test('saves and restores a selected theme', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.instance.setPreference(AppThemePreference.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_theme_preference'), 'light');
    expect(ThemeController.instance.themeMode, ThemeMode.light);

    await ThemeController.instance.setPreference(AppThemePreference.dark);
    expect(preferences.getString('app_theme_preference'), 'dark');
    expect(ThemeController.instance.themeMode, ThemeMode.dark);
  });
}
