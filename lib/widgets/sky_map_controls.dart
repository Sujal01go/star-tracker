import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../rendering/star_rendering_style.dart';

/// Floating minimalist control cluster for the sky map canvas.
class SkyMapControls extends StatelessWidget {
  final StarRenderingStyle style;
  final bool isTrackingActive;
  final bool hasSensors;
  final VoidCallback onToggleTracking;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleConstellations;
  final VoidCallback? onToggleConstellationArt;
  final VoidCallback? onToggleDeclutter;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleNightMode;
  final VoidCallback onResetView;

  const SkyMapControls({
    super.key,
    required this.style,
    required this.isTrackingActive,
    required this.hasSensors,
    required this.onToggleTracking,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleConstellations,
    this.onToggleConstellationArt,
    this.onToggleDeclutter,
    required this.onToggleGrid,
    required this.onToggleNightMode,
    required this.onResetView,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = style.nightMode;
    final btnBg = isNight
        ? const Color(0xDD250404)
        : AstroTrackColors.surface.withValues(alpha: 0.94);
    final borderColor = isNight
        ? const Color(0x66FF3333)
        : AstroTrackColors.line;
    final activeColor = isNight
        ? const Color(0xFFFF2222)
        : AstroTrackColors.accent;
    final inactiveColor = isNight
        ? const Color(0x88FF4444)
        : AstroTrackColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tracking AR compass toggle
        _controlButton(
          icon: isTrackingActive ? Icons.explore : Icons.touch_app,
          tooltip: isTrackingActive
              ? 'Tracking device orientation'
              : 'Touch pan mode (tap for device tracking)',
          backgroundColor: isTrackingActive
              ? (isNight
                    ? const Color(0xFF660E0E)
                    : AstroTrackColors.accentSoft)
              : btnBg,
          iconColor: isTrackingActive ? activeColor : inactiveColor,
          borderColor: isTrackingActive ? activeColor : borderColor,
          onPressed: onToggleTracking,
        ),

        const SizedBox(height: 8),

        // Zoom In
        _controlButton(
          icon: Icons.add,
          tooltip: 'Zoom in (narrow FOV)',
          backgroundColor: btnBg,
          iconColor: inactiveColor,
          borderColor: borderColor,
          onPressed: onZoomIn,
        ),

        const SizedBox(height: 6),

        // Zoom Out
        _controlButton(
          icon: Icons.remove,
          tooltip: 'Zoom out (wide FOV)',
          backgroundColor: btnBg,
          iconColor: inactiveColor,
          borderColor: borderColor,
          onPressed: onZoomOut,
        ),

        const SizedBox(height: 8),

        // Constellation lines toggle
        _controlButton(
          icon: Icons.hub_outlined,
          tooltip: 'Toggle constellation lines',
          backgroundColor: style.showConstellationLines
              ? (isNight
                    ? const Color(0xFF4A0A0A)
                    : AstroTrackColors.accentSoft)
              : btnBg,
          iconColor: style.showConstellationLines ? activeColor : inactiveColor,
          borderColor: borderColor,
          onPressed: onToggleConstellations,
        ),

        if (onToggleConstellationArt != null) ...[
          const SizedBox(height: 6),
          _controlButton(
            icon: Icons.auto_awesome,
            tooltip: 'Toggle constellation mythological artwork',
            backgroundColor: style.showConstellationArt
                ? (isNight
                      ? const Color(0xFF4A0A0A)
                      : AstroTrackColors.accentSoft)
                : btnBg,
            iconColor: style.showConstellationArt ? activeColor : inactiveColor,
            borderColor: borderColor,
            onPressed: onToggleConstellationArt!,
          ),
        ],

        if (onToggleDeclutter != null) ...[
          const SizedBox(height: 6),
          _controlButton(
            icon: style.hideLeastFamousStars
                ? Icons.filter_alt
                : Icons.filter_alt_off,
            tooltip: style.hideLeastFamousStars
                ? 'Decluttered: famous stars only (tap to show all)'
                : 'All stars visible (tap to declutter)',
            backgroundColor: style.hideLeastFamousStars
                ? (isNight
                      ? const Color(0xFF4A0A0A)
                      : AstroTrackColors.accentSoft)
                : btnBg,
            iconColor: style.hideLeastFamousStars ? activeColor : inactiveColor,
            borderColor: borderColor,
            onPressed: onToggleDeclutter!,
          ),
        ],

        const SizedBox(height: 6),

        // Celestial grid toggle
        _controlButton(
          icon: Icons.grid_4x4,
          tooltip: 'Toggle celestial grid',
          backgroundColor: style.showCelestialGrid
              ? (isNight
                    ? const Color(0xFF4A0A0A)
                    : AstroTrackColors.accentSoft)
              : btnBg,
          iconColor: style.showCelestialGrid ? activeColor : inactiveColor,
          borderColor: borderColor,
          onPressed: onToggleGrid,
        ),

        const SizedBox(height: 6),

        // Red Night-vision toggle
        _controlButton(
          icon: Icons.wb_twilight,
          tooltip: 'Toggle red night-vision mode',
          backgroundColor: isNight ? const Color(0xFF881111) : btnBg,
          iconColor: isNight ? Colors.white : inactiveColor,
          borderColor: isNight ? Colors.redAccent : borderColor,
          onPressed: onToggleNightMode,
        ),

        const SizedBox(height: 6),

        // Reset view to zenith/horizon
        _controlButton(
          icon: Icons.vertical_align_top,
          tooltip: 'Look toward zenith',
          backgroundColor: btnBg,
          iconColor: inactiveColor,
          borderColor: borderColor,
          onPressed: onResetView,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        elevation: 0.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(28.0),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}
