import 'package:flutter/material.dart';
import '../models/planet.dart';
import '../services/planet_data_service.dart';

/// Renders a planet image without decorative halo effects.
class PlanetThumbnail extends StatelessWidget {
  final String? planetName;
  final PlanetType? planetType;
  final double size;
  final String? heroTag;

  const PlanetThumbnail({
    super.key,
    this.planetName,
    this.planetType,
    this.size = 56.0,
    this.heroTag,
  }) : assert(
         planetName != null || planetType != null,
         'Either planetName or planetType must be supplied',
       );

  @override
  Widget build(BuildContext context) {
    final assetPath = planetType != null
        ? PlanetDataService.getAssetForType(planetType!)
        : PlanetDataService.getAssetForName(planetName!);

    Widget imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // A restrained shaded sphere keeps missing artwork legible.
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.35),
              radius: 0.9,
              colors: _fallbackColors(planetType),
            ),
          ),
        );
      },
    );

    if (heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: imageWidget),
    );
  }

  List<Color> _fallbackColors(PlanetType? type) {
    final palette = switch (type) {
      PlanetType.sun => const [
        Color(0xFFE4BF78),
        Color(0xFF986C3B),
        Color(0xFF211B18),
      ],
      PlanetType.moon => const [
        Color(0xFFD4D1C7),
        Color(0xFF777D82),
        Color(0xFF202731),
      ],
      PlanetType.mars => const [
        Color(0xFFC18472),
        Color(0xFF784C43),
        Color(0xFF211B20),
      ],
      PlanetType.jupiter || PlanetType.saturn => const [
        Color(0xFFD6C29E),
        Color(0xFF927B5E),
        Color(0xFF211B20),
      ],
      _ => const [Color(0xFFA0C6C2), Color(0xFF547A7C), Color(0xFF1D2730)],
    };
    return palette;
  }
}
