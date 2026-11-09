import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import '../rendering/star_rendering_style.dart';
import '../services/planet_data_service.dart';
import '../widgets/constellation_thumbnail.dart';
import '../widgets/planet_thumbnail.dart';

/// Full astrophysical breakdown of a selected star or Solar System planet matching
/// the Cosmic UI template design.
class StarDetailsScreen extends StatefulWidget {
  final Star? star;
  final Planet? planet;
  final AstronomyEngine astronomyEngine;
  final StarRenderingStyle style;
  final void Function(Planet planet)? onTrackPlanet;

  const StarDetailsScreen({
    super.key,
    this.star,
    this.planet,
    required this.astronomyEngine,
    required this.style,
    this.onTrackPlanet,
  }) : assert(
         star != null || planet != null,
         'Either star or planet must be provided',
       );

  @override
  State<StarDetailsScreen> createState() => _StarDetailsScreenState();
}

class _StarDetailsScreenState extends State<StarDetailsScreen> {
  String _formatRa(double raDeg) {
    final hoursTotal = raDeg / 15.0;
    final h = hoursTotal.floor();
    final m = ((hoursTotal - h) * 60.0).floor();
    final s = ((((hoursTotal - h) * 60.0) - m) * 60.0).toStringAsFixed(2);
    return '${h}h ${m}m ${s}s (${raDeg.toStringAsFixed(4)}°)';
  }

  String _formatDec(double decDeg) {
    final sign = decDeg >= 0 ? '+' : '-';
    final abs = decDeg.abs();
    final d = abs.floor();
    final m = ((abs - d) * 60.0).floor();
    final s = ((((abs - d) * 60.0) - m) * 60.0).toStringAsFixed(2);
    return '$sign$d° $m\' $s" (${decDeg.toStringAsFixed(4)}°)';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = AstroTrackColors.background;
    const cardBg = AstroTrackColors.surface;
    const borderColor = AstroTrackColors.line;
    const textPrimary = AstroTrackColors.textPrimary;
    const textSecondary = AstroTrackColors.textSecondary;
    const accentCyan = AstroTrackColors.accent;

    final isPlanet = widget.planet != null;
    final displayName = isPlanet
        ? widget.planet!.name
        : widget.star!.displayName;

    final SkyPosition pos = isPlanet
        ? (widget.astronomyEngine.solarSystemPositions[widget.planet!.id] ??
              widget.astronomyEngine.equatorialToHorizontal(
                widget.planet!.rightAscension,
                widget.planet!.declination,
              ))
        : widget.astronomyEngine.computeStarPosition(widget.star!);

    final hasPhysicalSpecs =
        isPlanet &&
        PlanetDataService.specs.containsKey(widget.planet!.name.toLowerCase());
    final specs = hasPhysicalSpecs
        ? PlanetDataService.getSpecs(widget.planet!.name)
        : null;
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          children: [
            // Hero Planet or Star sphere
            const SizedBox(height: 10),
            Center(
              child:
                  isPlanet && texturedPlanetTypes.contains(widget.planet!.type)
                  ? PlanetThumbnail(planetType: widget.planet!.type, size: 200)
                  : isPlanet
                  ? Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.planet!.baseColor.withValues(alpha: 0.16),
                        border: Border.all(
                          color: widget.planet!.baseColor.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.planet!.symbol,
                          style: TextStyle(
                            color: widget.planet!.baseColor,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.star!.color.withValues(alpha: 0.16),
                        border: Border.all(
                          color: widget.star!.color.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.star!.spectralType ?? 'Star',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 22),

            // Planet / Star Name
            Text(
              displayName,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 32.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (isPlanet)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${widget.planet!.symbol}  •  ${widget.planet!.phaseName}',
                  style: const TextStyle(
                    color: accentCyan,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${widget.star!.id} • ${widget.star!.constellationId ?? "N/A"}',
                  style: const TextStyle(
                    color: accentCyan,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // 6-Grid Stats layout matching photo!
            if (isPlanet && specs != null)
              _buildCosmicStatsGrid(specs)
            else if (isPlanet)
              _buildAdditionalBodyStats(widget.planet!)
            else
              _buildStarStatsGrid(),

            const SizedBox(height: 22),

            // Description / Educational Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: cardBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specs?.description ??
                        (isPlanet
                            ? (widget.planet!.description ??
                                  '${widget.planet!.type.name} in the Solar System; current apparent magnitude ${widget.planet!.apparentMagnitude.toStringAsFixed(2)}.')
                            : (widget.star!.description ??
                                  'Star in the constellation ${widget.star!.constellationId ?? "Unknown"}. Observed magnitude: ${widget.star!.apparentMagnitude}.')),
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  if (specs != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: accentCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            specs.funFact,
                            style: const TextStyle(
                              color: Color(0xFFB0C0E0),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Constellation banner for stars
            if (!isPlanet && widget.star!.constellationId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    ConstellationThumbnail(
                      constellationIdOrName: widget.star!.constellationId,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Constellation Pattern',
                            style: TextStyle(
                              color: accentCyan,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.star!.constellationId!,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Celestial IAU constellation mapping',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Live Sky Observation Coordinates Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: cardBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Real-Time Sky Coordinates',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _coordRow(
                    'Altitude',
                    '${pos.altitude.toStringAsFixed(1)}° (${pos.isVisible ? "Visible" : "Below Horizon"})',
                  ),
                  const Divider(color: Colors.white10),
                  _coordRow('Azimuth', '${pos.azimuth.toStringAsFixed(1)}°'),
                  const Divider(color: Colors.white10),
                  _coordRow(
                    'Right Ascension',
                    _formatRa(
                      isPlanet
                          ? widget.planet!.rightAscension
                          : widget.star!.rightAscension,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  _coordRow(
                    'Declination',
                    _formatDec(
                      isPlanet
                          ? widget.planet!.declination
                          : widget.star!.declination,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Prominent "Visit / Track in Sky" CTA Button (Solid, clean styling without gradients or glow)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (isPlanet && widget.onTrackPlanet != null) {
                    widget.onTrackPlanet!(widget.planet!);
                  }
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.explore_outlined),
                label: Text(
                  isPlanet
                      ? 'Visit ${widget.planet!.name}'
                      : 'Track in Sky Map',
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildCosmicStatsGrid(PlanetPhysicalSpecs specs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.scale_outlined,
                specs.mass,
                'Mass (10²⁴kg)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.arrow_downward,
                specs.gravity,
                'Gravity (m/s²)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.wb_sunny_outlined,
                specs.dayHours,
                'Day (hours)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.rocket_launch_outlined,
                specs.escVelocity,
                'Esc. Vel (km/s)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.thermostat_outlined,
                '${specs.meanTemp}°C',
                'Mean Temp',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.public,
                specs.distanceFromSun,
                'Dist (10⁶ km)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalBodyStats(Planet body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11182A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AstroTrackColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current ephemeris',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _coordRow('Object type', body.type.name),
          _coordRow(
            'Apparent magnitude',
            body.apparentMagnitude.toStringAsFixed(2),
          ),
          _coordRow(
            'Distance from Earth',
            '${body.distanceAu.toStringAsFixed(3)} AU',
          ),
          if (body.ephemerisSource != null)
            _coordRow('Orbit source', body.ephemerisSource!),
        ],
      ),
    );
  }

  Widget _buildStarStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.brightness_5,
                widget.star!.apparentMagnitude.toStringAsFixed(2),
                'Magnitude',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.category_outlined,
                widget.star!.spectralType ?? 'N/A',
                'Spectral Type',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.auto_awesome,
                widget.star!.constellationId ?? 'N/A',
                'Constellation',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.visibility_outlined,
                widget.star!.apparentMagnitude < 6.0
                    ? 'Naked Eye'
                    : 'Telescope',
                'Visibility',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: AstroTrackColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AstroTrackColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AstroTrackColors.accent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AstroTrackColors.textPrimary,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AstroTrackColors.textSecondary,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _coordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AstroTrackColors.textSecondary,
              fontSize: 13.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
