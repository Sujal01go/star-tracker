import 'package:flutter/material.dart';

/// Shared palette for AstroTrack's violet, rose, and saffron observing UI.
///
/// Keeping these values together gives the sky map, catalogue, and instruments
/// one consistent visual language. Keep them aligned with the root DESIGN.md.
class AstroTrackColors {
  static const background = Color(0xFF22162B); // Midnight Violet
  static const surface = Color(0xFF2F1F37);
  static const surfaceRaised = Color(0xFF451F55); // Dark Amethyst
  static const surfaceMuted = Color(0xFF35223E);
  static const line = Color(0xFF8C739B);
  static const textPrimary = Color(0xFFFFF8FD);
  static const textSecondary = Color(0xFFD9C9E0);
  static const textMuted = Color(0xFFC6B6CD);
  static const accent = Color(0xFFF16C85); // readable rose tint for text/icons
  static const action = Color(0xFFE54F6D); // Blush Rose
  static const accentStrong = Color(0xFF724E91); // Dusty Grape
  static const accentSoft = Color(0xFF50334F);
  static const warm = Color(0xFFF8C630); // Saffron
  static const secondary = Color(0xFF724E91); // Dusty Grape
  static const danger = Color(0xFFE54F6D);
}

/// Application theme definitions for AstroTrack.
class AstroTrackTheme {
  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: AstroTrackColors.action,
      secondary: AstroTrackColors.secondary,
      tertiary: AstroTrackColors.warm,
      surface: AstroTrackColors.surface,
      error: AstroTrackColors.danger,
      onPrimary: AstroTrackColors.background,
      onSecondary: Colors.white,
      onTertiary: AstroTrackColors.background,
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
          backgroundColor: AstroTrackColors.action,
          foregroundColor: AstroTrackColors.background,
          disabledBackgroundColor: AstroTrackColors.surfaceRaised,
          disabledForegroundColor: AstroTrackColors.textMuted,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AstroTrackColors.textPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AstroTrackColors.line),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AstroTrackColors.textPrimary,
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
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
        indicatorColor: AstroTrackColors.action,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? AstroTrackColors.background
                : AstroTrackColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AstroTrackColors.background
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
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AstroTrackColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AstroTrackColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AstroTrackColors.accent,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: AstroTrackColors.textSecondary),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AstroTrackColors.accent,
        inactiveTrackColor: AstroTrackColors.surfaceRaised,
        thumbColor: AstroTrackColors.accent,
        overlayColor: Color(0x33E54F6D),
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
        overlayColor: const WidgetStatePropertyAll(Color(0x33E54F6D)),
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
