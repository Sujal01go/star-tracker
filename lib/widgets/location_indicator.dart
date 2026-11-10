import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/observer_location.dart';
import '../rendering/star_rendering_style.dart';

/// Top bar indicator displaying active observer location and coordinates.
class LocationIndicator extends StatelessWidget {
  final ObserverLocation location;
  final StarRenderingStyle style;
  final VoidCallback onTap;

  const LocationIndicator({
    super.key,
    required this.location,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = style.nightMode;
    final bg = isNight
        ? const Color(0xDD250404)
        : AstroTrackColors.surface.withValues(alpha: 0.94);
    final border = isNight ? const Color(0x66FF3333) : AstroTrackColors.line;
    final textPrimary = style.textColor;
    final textSecondary = style.secondaryTextColor;

    final latStr = location.latitude >= 0
        ? '${location.latitude.toStringAsFixed(2)}°N'
        : '${(-location.latitude).toStringAsFixed(2)}°S';
    final lonStr = location.longitude >= 0
        ? '${location.longitude.toStringAsFixed(2)}°E'
        : '${(-location.longitude).toStringAsFixed(2)}°W';

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: border, width: 1.0),
      ),
      elevation: 2.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14.0,
                color: isNight ? Colors.redAccent : AstroTrackColors.accent,
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$latStr, $lonStr',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4.0),
              Icon(Icons.arrow_drop_down, size: 16.0, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
