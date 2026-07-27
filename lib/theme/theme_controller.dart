import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static const _storageKey = 'app_theme_preference';
  static final ThemeController instance = ThemeController._();

  AppThemePreference _preference = AppThemePreference.system;
  bool _isLoaded = false;

  AppThemePreference get preference => _preference;
  bool get isLoaded => _isLoaded;

  ThemeMode get themeMode {
    switch (_preference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _preference = _fromStoredValue(preferences.getString(_storageKey));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference && _isLoaded) return;
    _preference = preference;
    _isLoaded = true;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, preference.name);
  }

  static AppThemePreference _fromStoredValue(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}
