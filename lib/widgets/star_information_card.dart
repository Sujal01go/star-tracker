import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/constellation.dart';
import '../models/deep_sky_object.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import '../rendering/star_rendering_style.dart';
import '../services/constellation_asset_service.dart';
import '../services/planet_data_service.dart';
import 'constellation_thumbnail.dart';
import 'planet_thumbnail.dart';

/// Bottom card presenting selected star, planet, or constellation properties, physical astrometry, and local sky coordinates.
class StarInformationCard extends StatelessWidget {
  final Star? star;
  final Planet? planet;
  final Constellation? constellation;
  final DeepSkyObject? deepSkyObject;
  final SkyPosition? position;
  final StarRenderingStyle style;
  final VoidCallback onCenterView;
  final VoidCallback onFullDetails;
  final VoidCallback onClose;

  const StarInformationCard({
    super.key,
    this.star,
    this.planet,
    this.constellation,
    this.deepSkyObject,
    required this.position,
    required this.style,
    required this.onCenterView,
    required this.onFullDetails,
    required this.onClose,
  }) : assert(
         star != null ||
             planet != null ||
             constellation != null ||
             deepSkyObject != null,
         'A celestial object must be provided',
       );

  String _formatRa(double raDeg) {
    final hoursTotal = raDeg / 15.0;
    final h = hoursTotal.floor();
    final m = ((hoursTotal - h) * 60.0).floor();
    final s = ((((hoursTotal - h) * 60.0) - m) * 60.0).toStringAsFixed(1);
    return '${h}h ${m}m ${s}s';
  }

  String _formatDec(double decDeg) {
    final sign = decDeg >= 0 ? '+' : '-';
    final abs = decDeg.abs();
    final d = abs.floor();
    final m = ((abs - d) * 60.0).floor();
    final s = ((((abs - d) * 60.0) - m) * 60.0).toStringAsFixed(1);
    return '$sign$d° $m\' $s"';
  }

  String _azimuthCardinal(double az) {
    const cardinals = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final idx = ((az + 11.25) / 22.5).floor() % 16;
    return cardinals[idx];
  }

  String _planetTypeLabel(Planet body) {
    if (body.isSun || body.isMoon) return 'Solar System body';
    return switch (body.type) {
      PlanetType.pluto || PlanetType.dwarfPlanet => 'Dwarf planet',
      PlanetType.asteroid => 'Asteroid',
      PlanetType.comet => 'Comet',
      PlanetType.galileanMoon => 'Galilean moon',
      _ => 'Planet',
    };
  }

  String _starSummary(Star selectedStar) {
    final parts = <String>[];
    if (selectedStar.spectralType != null) {
      parts.add('${selectedStar.spectralType} star');
    }
    if (selectedStar.distanceLy != null) {
      parts.add(
        'about ${selectedStar.distanceLy!.toStringAsFixed(1)} light-years away',
      );
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final positionValue = position;
    final isNight = style.nightMode;
    final cardBg = isNight ? const Color(0xFF1E0505) : AstroTrackColors.surface;
    final borderColor = isNight
        ? const Color(0x66FF3333)
        : AstroTrackColors.line;
    final textPrimary = style.textColor;
    final textSecondary = style.secondaryTextColor;

    final isPlanet = planet != null;
    final isConstellation = constellation != null;
    final isDeepSky = deepSkyObject != null;

    final String displayName;
    late String subTitle;
    final double raValue;
    final double decValue;

    if (isPlanet) {
      displayName = '${planet!.symbol} ${planet!.name}';
      subTitle = '${planet!.phaseName} • Major Solar System Body';
      raValue = planet!.rightAscension;
      decValue = planet!.declination;
    } else if (isConstellation) {
      displayName = constellation!.name;
      subTitle =
          '${constellation!.englishName} • Constellation (${constellation!.id})';
      raValue = constellation!.centerRa;
      decValue = constellation!.centerDec;
    } else if (isDeepSky) {
      displayName = deepSkyObject!.name;
      subTitle =
          '${deepSkyObject!.catalogueName} • ${deepSkyObject!.objectType}';
      raValue = deepSkyObject!.rightAscension;
      decValue = deepSkyObject!.declination;
    } else {
      displayName = star!.displayName;
      subTitle =
          '${star!.id}${star!.constellationId != null ? ' • ${star!.constellationId}' : ''}';
      raValue = star!.rightAscension;
      decValue = star!.declination;
    }

    if (isPlanet) {
      subTitle = '${planet!.phaseName} • ${_planetTypeLabel(planet!)}';
    } else if (isDeepSky) {
      subTitle =
          '${deepSkyObject!.catalogueName} • ${deepSkyObject!.objectType} • ${deepSkyObject!.visibilityClass} target';
    }

    final dotColor = isNight
        ? const Color(0xFFFF3333)
        : (isPlanet
              ? planet!.baseColor
              : (isConstellation
                    ? AstroTrackColors.accent
                    : (isDeepSky ? const Color(0xFFFFCA80) : star!.color)));
    final double? magValue = isPlanet
        ? planet!.apparentMagnitude
        : (isConstellation
              ? 0.0
              : (isDeepSky
                    ? deepSkyObject!.apparentMagnitude
                    : star!.apparentMagnitude));
    final planetSpecs = isPlanet
        ? PlanetDataService.specs[planet!.name.toLowerCase()]
        : null;
    final description = isDeepSky
        ? '${deepSkyObject!.description}'
              '${deepSkyObject!.distanceLightYears == null ? '' : ' Distance: ${deepSkyObject!.distanceLightYears!.toStringAsFixed(0)} light-years.'}'
              '${deepSkyObject!.constellation == null ? '' : ' Constellation: ${deepSkyObject!.constellation}.'}'
        : (isPlanet
              ? (planet!.description ??
                    planetSpecs?.description ??
                    'Position computed for the selected observation time.')
              : (isConstellation
                    ? '${constellation!.name} is an IAU constellation with ${constellation!.lines.length} mapped outline segments.'
                    : (star?.description ?? _starSummary(star!))));
    const texturedPlanetTypes = {
      PlanetType.sun,
      PlanetType.moon,
      PlanetType.mercury,
      PlanetType.venus,
      PlanetType.mars,
      PlanetType.jupiter,
      PlanetType.saturn,
      PlanetType.uranus,
      PlanetType.neptune,
      PlanetType.pluto,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Badge: 3D Planet Image, Constellation Artwork Thumbnail, or Star Color Dot
              if (isPlanet && texturedPlanetTypes.contains(planet!.type))
                PlanetThumbnail(planetType: planet!.type, size: 38)
              else if (isConstellation)
                ConstellationThumbnail(
                  constellationIdOrName: constellation!.id,
                  size: 40,
                )
              else if (isDeepSky || isPlanet)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: 0.2),
                    border: Border.all(color: dotColor.withValues(alpha: 0.7)),
                  ),
                  alignment: Alignment.center,
                  child: isDeepSky
                      ? Icon(Icons.blur_on, size: 23, color: dotColor)
                      : Text(
                          planet!.symbol,
                          style: TextStyle(
                            color: dotColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              else
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subTitle,
                      style: TextStyle(color: textSecondary, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              if (star?.constellationId != null) ...[
                const SizedBox(width: 8),
                ConstellationThumbnail(
                  constellationIdOrName: star!.constellationId,
                  size: 36,
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: Icon(Icons.close, color: textSecondary, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Key metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isConstellation)
                _metricTile(
                  title: 'ASTERISM',
                  value: '${constellation!.lines.length} lines',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                )
              else if (magValue != null)
                _metricTile(
                  title: 'MAGNITUDE',
                  value: magValue.toStringAsFixed(2),
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                ),
              if (isDeepSky && magValue == null)
                _metricTile(
                  title: 'MAGNITUDE',
                  value: 'Not catalogued',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                ),
              if (isPlanet)
                _metricTile(
                  title: 'DISTANCE',
                  value: '${planet!.distanceMillionKm.toStringAsFixed(1)}M km',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                )
              else if (isConstellation)
                _metricTile(
                  title: 'FIGURE',
                  value: ConstellationAssetService.hasArtwork(constellation!.id)
                      ? 'Myth Figure'
                      : 'Celestial',
                  primaryColor: isNight
                      ? Colors.redAccent
                      : AstroTrackColors.accent,
                  subColor: textSecondary,
                )
              else if (isDeepSky)
                _metricTile(
                  title: 'ANGULAR SIZE',
                  value: deepSkyObject!.angularSizeMajorArcminutes == null
                      ? 'Not catalogued'
                      : '${deepSkyObject!.angularSizeMajorArcminutes!.toStringAsFixed(0)}′',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                )
              else
                _metricTile(
                  title: 'SPECTRAL',
                  value: star!.spectralType ?? '—',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                ),
              if (position != null)
                _metricTile(
                  title: 'ALTITUDE',
                  value: '${position!.altitude.toStringAsFixed(1)}°',
                  primaryColor: position!.isVisible
                      ? (isNight ? Colors.redAccent : const Color(0xFF4ECCA3))
                      : textSecondary,
                  subColor: textSecondary,
                ),
              if (position != null)
                _metricTile(
                  title: 'AZIMUTH',
                  value:
                      '${position!.azimuth.toStringAsFixed(1)}° ${_azimuthCardinal(position!.azimuth)}',
                  primaryColor: textPrimary,
                  subColor: textSecondary,
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Equatorial coordinates preview
          Row(
            children: [
              Icon(Icons.explore_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'RA: ${_formatRa(raValue)}  |  Dec: ${_formatDec(decValue)}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          if (positionValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                positionValue.isVisible ? 'Above horizon' : 'Below horizon',
                style: TextStyle(
                  color: positionValue.isVisible
                      ? const Color(0xFF4ECCA3)
                      : textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              description,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.5,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Center Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isNight
                        ? Colors.redAccent
                        : AstroTrackColors.accent,
                    side: BorderSide(
                      color: isNight
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : AstroTrackColors.accent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onCenterView,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Full Details'),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isNight
                        ? const Color(0xFF881111)
                        : AstroTrackColors.accentStrong,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onFullDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required Color primaryColor,
    required Color subColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: subColor,
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
