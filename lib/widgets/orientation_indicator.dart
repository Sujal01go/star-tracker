import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../rendering/star_rendering_style.dart';
import '../sensors/heading_calibration.dart';

/// Minimal HUD indicator showing camera heading (Az, Alt), sensor accuracy, and calibration status.
class OrientationIndicator extends StatelessWidget {
  final double azimuth;
  final double altitude;
  final bool isTracking;
  final SensorAccuracy accuracy;
  final StarRenderingStyle style;
  final VoidCallback onTap;

  const OrientationIndicator({
    super.key,
    required this.azimuth,
    required this.altitude,
    required this.isTracking,
    required this.accuracy,
    required this.style,
    required this.onTap,
  });

  String _cardinal(double az) {
    const list = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((az + 22.5) / 45.0).floor() % 8;
    return list[idx];
  }

  Color _accuracyColor() {
    switch (accuracy) {
      case SensorAccuracy.high:
        return const Color(0xFF2ED573);
      case SensorAccuracy.medium:
        return const Color(0xFFFFA502);
      case SensorAccuracy.low:
      case SensorAccuracy.unreliable:
        return const Color(0xFFFF4757);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = style.nightMode;
    final bg = isNight
        ? const Color(0xDD250404)
        : AstroTrackColors.surface.withValues(alpha: 0.94);
    final border = isNight ? const Color(0x66FF3333) : AstroTrackColors.line;
    final textPrimary = style.textColor;
    final textSecondary = style.secondaryTextColor;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: border, width: 1.0),
      ),
      elevation: 2.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accuracy status dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTracking ? _accuracyColor() : textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Az ${azimuth.toStringAsFixed(0)}° ${_cardinal(azimuth)}  Alt ${altitude.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 11.0,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isTracking) ...[
                const SizedBox(width: 4),
                Text(
                  '• AR',
                  style: TextStyle(
                    color: isNight ? Colors.redAccent : AstroTrackColors.accent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
