import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/planet.dart';

/// Physical specifications and astrometric stats for Solar System bodies.
class PlanetPhysicalSpecs {
  final String mass; // e.g. "5.97" (10^24 kg)
  final String massUnit;
  final String gravity; // e.g. "9.8" (m/s^2)
  final String dayHours; // e.g. "24"
  final String escVelocity; // e.g. "11.2" (km/s)
  final String meanTemp; // e.g. "15" (°C)
  final String distanceFromSun; // e.g. "149.6" (10^6 km)
  final String description;
  final String funFact;

  const PlanetPhysicalSpecs({
    required this.mass,
    this.massUnit = '10²⁴ kg',
    required this.gravity,
    required this.dayHours,
    required this.escVelocity,
    required this.meanTemp,
    required this.distanceFromSun,
    required this.description,
    required this.funFact,
  });
}

/// Service providing assets, metadata, and cached ui.Image instances for planets.
class PlanetDataService {
  static const Map<PlanetType, String> assetPaths = {
    PlanetType.sun: 'assets/planets/sun.png',
    PlanetType.moon: 'assets/planets/moon.png',
    PlanetType.mercury: 'assets/planets/mercury.png',
    PlanetType.venus: 'assets/planets/venus.png',
    PlanetType.mars: 'assets/planets/mars.png',
    PlanetType.jupiter: 'assets/planets/jupiter.png',
    PlanetType.saturn: 'assets/planets/saturn.png',
    PlanetType.uranus: 'assets/planets/uranus.png',
    PlanetType.neptune: 'assets/planets/neptune.png',
    PlanetType.pluto: 'assets/planets/pluto.png',
  };

  /// Earth asset path
  static const String earthAssetPath = 'assets/planets/earth.png';
  static const String cosmicBackgroundPath = 'assets/images/cosmic_bg.png';

  static String getAssetForType(PlanetType type) {
    return assetPaths[type] ?? earthAssetPath;
  }

  static String getAssetForName(String name) {
    final lower = name.trim().toLowerCase();
    if (lower == 'earth') return earthAssetPath;
    for (final entry in assetPaths.entries) {
      if (entry.key.name.toLowerCase() == lower) {
        return entry.value;
      }
    }
    return earthAssetPath;
  }

  static const Map<String, PlanetPhysicalSpecs> specs = {
    'mercury': PlanetPhysicalSpecs(
      mass: '0.33',
      gravity: '3.7',
      dayHours: '4222',
      escVelocity: '4.3',
      meanTemp: '167',
      distanceFromSun: '57.9',
      description:
          'Mercury is the smallest planet in the Solar System and the closest to the Sun. Its orbit around the Sun takes 87.97 Earth days, the shortest of all planets.',
      funFact: 'A year on Mercury is just 88 Earth days long!',
    ),
    'venus': PlanetPhysicalSpecs(
      mass: '4.87',
      gravity: '8.9',
      dayHours: '2802',
      escVelocity: '10.4',
      meanTemp: '464',
      distanceFromSun: '108.2',
      description:
          'Venus is the second planet from the Sun and Earth\'s closest planetary neighbor. It is the hottest planet in the Solar System due to an intense greenhouse effect.',
      funFact: 'Venus rotates backwards compared to most other planets!',
    ),
    'earth': PlanetPhysicalSpecs(
      mass: '5.97',
      gravity: '9.8',
      dayHours: '24',
      escVelocity: '11.2',
      meanTemp: '15',
      distanceFromSun: '149.6',
      description:
          'Earth is an ellipsoid with a circumference of about 40,000 km. It is the densest planet in the Solar System and the only planet known to harbor life.',
      funFact: 'About 71% of Earth\'s surface is covered with water.',
    ),
    'mars': PlanetPhysicalSpecs(
      mass: '0.64',
      gravity: '3.7',
      dayHours: '24.6',
      escVelocity: '5.0',
      meanTemp: '-65',
      distanceFromSun: '227.9',
      description:
          'Mars is the fourth planet from the Sun and the second smallest planet in the Solar System, only being larger than Mercury. It is known as the Red Planet.',
      funFact:
          'Mars is home to Olympus Mons, the largest volcano in the Solar System.',
    ),
    'jupiter': PlanetPhysicalSpecs(
      mass: '1898',
      gravity: '24.8',
      dayHours: '9.9',
      escVelocity: '59.5',
      meanTemp: '-110',
      distanceFromSun: '778.6',
      description:
          'Jupiter is the largest planet in the Solar System. It is a gas giant with a mass more than two and a half times that of all other planets combined.',
      funFact:
          'Jupiter\'s Great Red Spot is a gigantic storm larger than Earth!',
    ),
    'saturn': PlanetPhysicalSpecs(
      mass: '568',
      gravity: '10.4',
      dayHours: '10.7',
      escVelocity: '35.5',
      meanTemp: '-140',
      distanceFromSun: '1433',
      description:
          'Saturn is the sixth planet from the Sun and famous for its prominent, dazzling ring system made of billions of chunks of ice and rock.',
      funFact:
          'Saturn has a lower density than water—it could float in a giant bathtub!',
    ),
    'uranus': PlanetPhysicalSpecs(
      mass: '86.8',
      gravity: '8.7',
      dayHours: '17.2',
      escVelocity: '21.3',
      meanTemp: '-195',
      distanceFromSun: '2872',
      description:
          'Uranus is an ice giant with a unique sideways tilt: its axis of rotation is tilted by 98 degrees, rolling like a ball around its orbit.',
      funFact: 'Uranus was the first planet discovered using a telescope.',
    ),
    'neptune': PlanetPhysicalSpecs(
      mass: '102',
      gravity: '11.2',
      dayHours: '16.1',
      escVelocity: '23.5',
      meanTemp: '-200',
      distanceFromSun: '4495',
      description:
          'Neptune is the eighth and farthest known major planet from the Sun. It has the strongest sustained supersonic winds in the Solar System, up to 2,100 km/h.',
      funFact:
          'Neptune takes about 165 Earth years to complete one orbit around the Sun.',
    ),
    'sun': PlanetPhysicalSpecs(
      mass: '1989000',
      gravity: '274',
      dayHours: '600',
      escVelocity: '617.7',
      meanTemp: '5505',
      distanceFromSun: '0',
      description:
          'The Sun is the radiant yellow dwarf star at the center of our Solar System, containing 99.86% of the system\'s entire mass.',
      funFact: '1.3 million Earths could fit inside the Sun!',
    ),
    'moon': PlanetPhysicalSpecs(
      mass: '0.073',
      gravity: '1.6',
      dayHours: '708',
      escVelocity: '2.4',
      meanTemp: '-20',
      distanceFromSun: '149.6',
      description:
          'Earth\'s only natural satellite in synchronous rotation. Its gravitational pull produces Earth\'s ocean tides.',
      funFact:
          'Footprints left on the Moon by Apollo astronauts will stay for millions of years.',
    ),
    'pluto': PlanetPhysicalSpecs(
      mass: '0.013',
      gravity: '0.62',
      dayHours: '153',
      escVelocity: '1.2',
      meanTemp: '-225',
      distanceFromSun: '5906',
      description:
          'Pluto is a dwarf planet in the Kuiper belt, covered with nitrogen, methane, and carbon monoxide ice and home to the bright heart-shaped Tombaugh Regio.',
      funFact: 'Pluto was named by an 11-year-old girl from Oxford, England.',
    ),
  };

  static PlanetPhysicalSpecs getSpecs(String name) {
    return specs[name.trim().toLowerCase()] ?? specs['earth']!;
  }

  // Preloaded ui.Image cache for Canvas painting
  static final Map<PlanetType, ui.Image> _uiImageCache = {};
  static Future<void>? _loadingImages;

  static Map<PlanetType, ui.Image> get uiImages => _uiImageCache;

  /// Loads all planet PNG assets into memory as dart:ui.Image objects.
  static Future<void> preloadUiImages() {
    if (_uiImageCache.length >= assetPaths.length) return Future.value();
    return _loadingImages ??= _loadUiImages();
  }

  static Future<void> _loadUiImages() async {
    try {
      final loadedImages = <PlanetType, ui.Image>{};
      await Future.wait(
        assetPaths.entries.map((entry) async {
          try {
            final data = await rootBundle.load(entry.value);
            final codec = await ui.instantiateImageCodec(
              data.buffer.asUint8List(),
            );
            final frameInfo = await codec.getNextFrame();
            loadedImages[entry.key] = frameInfo.image;
          } catch (e) {
            debugPrint('Could not load planet ui.Image for ${entry.key}: $e');
          }
        }),
      );
      _uiImageCache.addAll(loadedImages);
    } finally {
      _loadingImages = null;
    }
  }
}
