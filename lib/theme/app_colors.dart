import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceLight = Color(0xFF222222);

  // Primary
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA855F7);

  // Status
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF6B7280);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF8A8A8A);

  // Others
  static const Color divider = Color(0xFF2B2B2B);
  static const Color cardBorder = Color(0xFF2F2F2F);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF7C3AED),
      Color(0xFFA855F7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}