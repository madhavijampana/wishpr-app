import 'package:flutter/material.dart';

import 'wishpr_colors.dart';
import 'wishpr_constants.dart';
import 'wishpr_typography.dart';

/// Assembles [ThemeData] for the Wishpr dark premium look.
abstract final class WishprTheme {
  static ThemeData get dark {
    final base = WishprColors.darkScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: WishprColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: WishprColors.surface,
        foregroundColor: WishprColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: WishprTypography.appBarTitle,
      ),
      cardTheme: CardThemeData(
        color: WishprColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WishprLayout.cardRadius),
          side: BorderSide(
            color: WishprColors.primary.withValues(alpha: 0.12),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          ),
          side: BorderSide(color: WishprColors.primary.withValues(alpha: 0.45)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: WishprColors.onSurface.withValues(alpha: 0.75),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: WishprColors.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: WishprColors.onSurface.withValues(alpha: 0.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WishprColors.surface,
        indicatorColor: WishprColors.primary.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? WishprColors.primary
                : WishprColors.onSurface.withValues(alpha: 0.65),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? WishprColors.primary
                : WishprColors.onSurface.withValues(alpha: 0.55),
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: WishprColors.onSurface.withValues(alpha: 0.08),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WishprColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: TextStyle(
          color: WishprColors.onSurface.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final focused = states.contains(WidgetState.focused);
          return TextStyle(
            color: focused
                ? WishprColors.primary
                : WishprColors.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          );
        }),
        hintStyle: TextStyle(color: WishprColors.onSurface.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          borderSide: BorderSide(
            color: WishprColors.onSurface.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          borderSide: BorderSide(
            color: WishprColors.onSurface.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          borderSide: const BorderSide(color: WishprColors.primary, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return WishprColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(base.onPrimary),
        side: BorderSide(color: WishprColors.onSurface.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return WishprColors.primary;
          }
          return WishprColors.onSurface.withValues(alpha: 0.55);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return WishprColors.primary.withValues(alpha: 0.35);
          }
          return WishprColors.surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (_) => WishprColors.onSurface.withValues(alpha: 0.2),
        ),
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: WishprColors.onSurface,
        displayColor: WishprColors.onSurface,
      ),
    );
  }
}
