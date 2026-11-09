import 'package:flutter/material.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/constellation_repository.dart';
import '../data/star_catalogue_repository.dart';
import '../screens/cosmic_main_screen.dart';
import '../sensors/device_orientation_service.dart';
import '../services/preferences_service.dart';
import 'theme.dart';

/// Root application widget for AstroTrack with Cosmic UI design system.
class AstroTrackApp extends StatelessWidget {
  final StarCatalogueRepository starRepository;
  final ConstellationRepository constellationRepository;
  final AstronomyEngine astronomyEngine;
  final DeviceOrientationService orientationService;
  final PreferencesService? preferencesService;
  final int initialTabIndex;

  const AstroTrackApp({
    super.key,
    required this.starRepository,
    required this.constellationRepository,
    required this.astronomyEngine,
    required this.orientationService,
    this.preferencesService,
    this.initialTabIndex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmic - Solar System & Star Tracker',
      debugShowCheckedModeBanner: false,
      theme: AstroTrackTheme.darkTheme(),
      home: CosmicMainScreen(
        starRepository: starRepository,
        constellationRepository: constellationRepository,
        astronomyEngine: astronomyEngine,
        orientationService: orientationService,
        preferencesService: preferencesService,
        initialTabIndex: initialTabIndex,
      ),
    );
  }
}
