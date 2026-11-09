import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Rendering visual styles, theme colors, and magnitude thresholds.
class StarRenderingStyle {
  final bool nightMode; // Red night-vision mode for dark adaptation
  final bool showConstellationLines;
  final bool showConstellationNames;
  final bool showConstellationArt;
  final bool showCelestialGrid;
  final bool showStarLabels;
  final bool showHorizon;
  final bool hideLeastFamousStars;
  final double limitingMagnitude;
  final double starSizeScale;

  const StarRenderingStyle({
    this.nightMode = false,
    this.showConstellationLines = true,
    this.showConstellationNames = true,
    this.showConstellationArt = true,
    this.showCelestialGrid = true,
    this.showStarLabels = true,
    this.showHorizon = true,
    this.hideLeastFamousStars = true,
    this.limitingMagnitude = 6.0,
    this.starSizeScale = 1.0,
  });

  // Background sky gradients
  Color get skyZenithColor =>
      nightMode ? const Color(0xFF100202) : AstroTrackColors.background;
  Color get skyHorizonColor =>
      nightMode ? const Color(0xFF220505) : AstroTrackColors.surfaceMuted;
  Color get groundColor =>
      nightMode ? const Color(0xFF0D0000) : const Color(0xFF030508);

  // Line elements
  Color get constellationLineColor => nightMode
      ? const Color(0xAAFF3333)
      : AstroTrackColors.secondary.withValues(alpha: 0.72);
  Color get gridLineColor =>
      nightMode ? const Color(0x28FF2222) : const Color(0x2088AAFF);
  Color get horizonLineColor => nightMode
      ? const Color(0xAAFF3333)
      : AstroTrackColors.accentStrong.withValues(alpha: 0.72);

  // Typography
  Color get textColor =>
      nightMode ? const Color(0xFFFF5555) : AstroTrackColors.textPrimary;
  Color get secondaryTextColor =>
      nightMode ? const Color(0xAAFF4444) : AstroTrackColors.textSecondary;
  Color get cardinalColor =>
      nightMode ? const Color(0xFFFF2222) : AstroTrackColors.warm;

  // Selection
  Color get selectionColor =>
      nightMode ? const Color(0xFFFF2222) : AstroTrackColors.accent;

  /// Computes rendered screen radius (in pixels) for a star given its apparent magnitude.
  double getStarRadius(double magnitude) {
    // Brighter stars (lower magnitude) have larger radius:
    // Pogson-inspired non-linear scaling
    final double baseRadius = (4.8 - (0.65 * magnitude)) * starSizeScale;
    return math.max(1.2, math.min(baseRadius, 7.5));
  }

  /// Calculates star alpha/opacity based on limiting magnitude fade.
  double getStarAlpha(double magnitude) {
    if (magnitude <= limitingMagnitude - 1.0) return 1.0;
    if (magnitude > limitingMagnitude) return 0.0;
    // Smooth fade near threshold
    return (limitingMagnitude - magnitude).clamp(0.1, 1.0);
  }

  StarRenderingStyle copyWith({
    bool? nightMode,
    bool? showConstellationLines,
    bool? showConstellationNames,
    bool? showConstellationArt,
    bool? showCelestialGrid,
    bool? showStarLabels,
    bool? showHorizon,
    bool? hideLeastFamousStars,
    double? limitingMagnitude,
    double? starSizeScale,
  }) {
    return StarRenderingStyle(
      nightMode: nightMode ?? this.nightMode,
      showConstellationLines:
          showConstellationLines ?? this.showConstellationLines,
      showConstellationNames:
          showConstellationNames ?? this.showConstellationNames,
      showConstellationArt: showConstellationArt ?? this.showConstellationArt,
      showCelestialGrid: showCelestialGrid ?? this.showCelestialGrid,
      showStarLabels: showStarLabels ?? this.showStarLabels,
      showHorizon: showHorizon ?? this.showHorizon,
      hideLeastFamousStars: hideLeastFamousStars ?? this.hideLeastFamousStars,
      limitingMagnitude: limitingMagnitude ?? this.limitingMagnitude,
      starSizeScale: starSizeScale ?? this.starSizeScale,
    );
  }
}
