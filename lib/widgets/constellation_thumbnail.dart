import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/constellation_asset_service.dart';

/// Renders a constellation artwork thumbnail with a quiet, consistent frame.
class ConstellationThumbnail extends StatelessWidget {
  final String? constellationIdOrName;
  final double size;
  final BorderRadius? borderRadius;

  const ConstellationThumbnail({
    super.key,
    required this.constellationIdOrName,
    this.size = 56.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = ConstellationAssetService.getArtworkForConstellation(
      constellationIdOrName,
    );
    final r = borderRadius ?? BorderRadius.circular(14.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        color: AstroTrackColors.surfaceMuted,
        border: Border.all(
          color: AstroTrackColors.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AstroTrackColors.surfaceRaised,
            child: const Icon(
              Icons.auto_awesome,
              color: AstroTrackColors.accent,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
