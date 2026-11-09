import 'package:flutter/material.dart';

/// Shared palette for a quiet, space-inspired observing interface.
///
/// Keeping these values together gives the sky map, catalogue, and instruments
/// one consistent visual language. Keep them aligned with the root DESIGN.md.
class AstroTrackColors {
  static const background = Color(0xFF0B1420);
  static const surface = Color(0xFF121F2B);
  static const surfaceRaised = Color(0xFF1A2A38);
  static const surfaceMuted = Color(0xFF162633);
  static const line = Color(0xFF2B3D4B);
  static const textPrimary = Color(0xFFF1F4F2);
  static const textSecondary = Color(0xFFB2BEC5);
  static const textMuted = Color(0xFF8796A0);
  static const accent = Color(0xFF9CCBC4);
  static const accentStrong = Color(0xFF426E69);
  static const accentSoft = Color(0xFF213A39);
  static const warm = Color(0xFFD9BC88);
  static const secondary = Color(0xFFADB8CE);
  static const danger = Color(0xFFD98282);
}

/// Application theme definitions for AstroTrack.
class AstroTrackTheme {
  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: AstroTrackColors.accent,
      secondary: AstroTrackColors.secondary,
      tertiary: AstroTrackColors.warm,
      surface: AstroTrackColors.surface,
      error: AstroTrackColors.danger,
      onPrimary: Color(0xFF10201E),
      onSecondary: Color(0xFF14212B),
      onTertiary: Color(0xFF2B2108),
      onSurface: AstroTrackColors.textPrimary,
      onSurfaceVariant: AstroTrackColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AstroTrackColors.background,
      colorScheme: scheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AstroTrackColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AstroTrackColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
      ),
      cardTheme: CardThemeData(
        color: AstroTrackColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AstroTrackColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AstroTrackColors.accentStrong,
          foregroundColor: AstroTrackColors.textPrimary,
          disabledBackgroundColor: AstroTrackColors.surfaceRaised,
          disabledForegroundColor: AstroTrackColors.textMuted,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AstroTrackColors.accent,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AstroTrackColors.surface,
        indicatorColor: AstroTrackColors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? AstroTrackColors.textPrimary
                : AstroTrackColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AstroTrackColors.accent
                : AstroTrackColors.textMuted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x332B3D4B),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AstroTrackColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AstroTrackColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AstroTrackColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AstroTrackColors.accent,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: AstroTrackColors.textSecondary),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AstroTrackColors.accent,
        inactiveTrackColor: Color(0xFF33434F),
        thumbColor: AstroTrackColors.accent,
        overlayColor: Color(0x339CCBC4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AstroTrackColors.background
              : AstroTrackColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AstroTrackColors.accent
              : AstroTrackColors.surfaceRaised;
        }),
        trackOutlineColor: WidgetStateProperty.all(AstroTrackColors.line),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AstroTrackColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AstroTrackColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// High-contrast red night-vision theme to preserve retinal rhodopsin during dark sky sessions.
  static ThemeData nightVisionTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0202),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF2222),
        secondary: Color(0xFF881111),
        surface: Color(0xFF1E0505),
        error: Color(0xFFFF4444),
        onPrimary: Colors.white,
        onSurface: Color(0xFFFF6666),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0202),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFFFF2222),
        thumbColor: Color(0xFFFF2222),
        overlayColor: Color(0x33FF2222),
      ),
    );
  }
}
