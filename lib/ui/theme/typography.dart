import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Poppins font
class AppTypography {
  // Display - Hero titles
  static TextStyle display(BuildContext context, {Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.2,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  // Headline - Screen titles
  static TextStyle headline(
    BuildContext context, {
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: weight ?? FontWeight.w600,
      height: 1.3,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle headlineSmall(BuildContext context, {Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  // Body - Content
  static TextStyle body(
    BuildContext context, {
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: weight ?? FontWeight.normal,
      height: 1.5,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle bodySmall(
    BuildContext context, {
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: weight ?? FontWeight.normal,
      height: 1.5,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  // Label - Buttons, chips
  static TextStyle label(
    BuildContext context, {
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: weight ?? FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.5,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.5,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
