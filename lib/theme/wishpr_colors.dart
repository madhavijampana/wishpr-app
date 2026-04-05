import 'package:flutter/material.dart';

/// Wishpr dark purple / blue palette and derived [ColorScheme].
abstract final class WishprColors {
  static const Color background = Color(0xFF0D0614);
  static const Color surface = Color(0xFF161022);
  static const Color surfaceHigh = Color(0xFF231A35);
  static const Color primary = Color(0xFFB388FF);
  static const Color secondary = Color(0xFF5C9DFF);
  static const Color onSurface = Color(0xFFE8E2F4);
  static const Color onPrimary = Color(0xFF1A0D2E);
  static const Color primaryContainer = Color(0xFF3D2A5C);
  static const Color onPrimaryContainer = Color(0xFFE8DDFF);
  static const Color onSecondary = Color(0xFF001A33);
  static const Color secondaryContainer = Color(0xFF1E3A5C);
  static const Color onSecondaryContainer = Color(0xFFD4E4FF);
  static const Color outline = Color(0xFF4A3F5C);
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);

  static ColorScheme get darkScheme => ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceHigh,
        outline: outline,
        error: error,
        onError: onError,
      );
}
