import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../rendering/star_rendering_style.dart';

/// Quick bottom-sheet or overlay for tuning limiting magnitude and star brightness.
class BrightnessControl extends StatelessWidget {
  final StarRenderingStyle style;
  final ValueChanged<double> onMagnitudeChanged;
  final ValueChanged<double> onScaleChanged;

  const BrightnessControl({
    super.key,
    required this.style,
    required this.onMagnitudeChanged,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = style.nightMode;
    final bg = isNight ? const Color(0xFF1E0505) : AstroTrackColors.surface;
    final textPrimary = style.textColor;
    final textSecondary = style.secondaryTextColor;
    final activeColor = isNight ? Colors.redAccent : AstroTrackColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isNight ? const Color(0x66FF3333) : AstroTrackColors.line,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIMITING MAGNITUDE: ${style.limitingMagnitude.toStringAsFixed(1)}',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _magnitudeDescription(style.limitingMagnitude),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: textSecondary.withValues(alpha: 0.2),
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.15),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: style.limitingMagnitude,
              min: 1.0,
              max: 7.0,
              divisions: 24,
              onChanged: onMagnitudeChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _magnitudeDescription(double mag) {
    if (mag <= 2.0) return 'Bright city sky';
    if (mag <= 4.0) return 'Suburban sky';
    if (mag <= 5.5) return 'Rural sky';
    return 'Dark sky site';
  }
}
