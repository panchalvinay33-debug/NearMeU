import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: Color(0xFFFB7185),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    const rounded16 = BorderRadius.all(Radius.circular(16));
    const rounded20 = BorderRadius.all(Radius.circular(20));

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.18,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: rounded20,
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: const OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: Color(0xFFFB7185)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: Color(0xFFFB7185), width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textHint,
          shape: const RoundedRectangleBorder(borderRadius: rounded16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: rounded16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: const RoundedRectangleBorder(borderRadius: rounded16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: const Color(0xFF111111),
        indicatorColor: AppColors.primary.withValues(alpha: .18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryLight
                : AppColors.textHint,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textHint,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Color(0xFF111111),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF262626),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceLight,
      ),
    );
  }
}
