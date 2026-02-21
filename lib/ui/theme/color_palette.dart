import 'package:flutter/material.dart';

/// Color palette for the carpooling app
class AppColors {
  // Primary - Bright Teal/Mint
  static const Color primaryLight = Color(0xFF1DE9B6);
  static const Color primaryDark = Color(0xFF00D9B5);
  static const Color primaryContainer = Color(0xFFE0F7F4);

  // Secondary - Warm Coral/Orange
  static const Color secondaryLight = Color(0xFFFF8A65);
  static const Color secondaryDark = Color(0xFFFF6B6B);
  static const Color secondaryContainer = Color(0xFFFFE8E0);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Female-only indicator
  static const Color femaleOnly = Color(0xFFE91E63);
  static const Color femaleOnlyLight = Color(0xFFFCE4EC);

  // Neutral colors - Light theme
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // Neutral colors - Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryDark, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
