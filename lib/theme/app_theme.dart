import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.background : const Color(0xFFF7F5FB);
    final surface = isDark ? AppColors.surface : Colors.white;
    final surfaceAlt = isDark ? AppColors.surfaceLight : const Color(0xFFF0EBF5);
    final border = isDark ? AppColors.cardBorder : const Color(0xFFE5DFEC);
    final text = isDark ? AppColors.textPrimary : const Color(0xFF1D1725);
    final muted = isDark ? AppColors.textSecondary : const Color(0xFF6F6679);
    final hint = isDark ? AppColors.textHint : const Color(0xFF94899E);
    final navigation = isDark ? const Color(0xFF111111) : Colors.white;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      outline: border,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text).copyWith(
            bodyMedium: TextStyle(color: muted, fontSize: 14, height: 1.4),
            titleLarge: TextStyle(color: text, fontWeight: FontWeight.w800),
            titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
          ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: navigation,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: hint,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: navigation,
        indicatorColor: AppColors.primary.withValues(alpha: .18),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFF2A2430),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: surfaceAlt,
      ),
    );
  }
}
