import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'astronomy/astronomy_engine.dart';
import 'data/constellation_repository.dart';
import 'data/star_catalogue_repository.dart';
import 'sensors/device_orientation_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation or let sensor handle it smoothly
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make system bars transparent for edge-to-edge astronomical viewing
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize preferences
  PreferencesService? preferencesService;
  try {
    preferencesService = await PreferencesService.init();
  } catch (e) {
    debugPrint('Preferences initialization failed: $e');
  }

  // Load saved location or fallback
  final savedLocation = preferencesService?.loadLocation();

  // Initialize repositories
  final starRepository = StarCatalogueRepository();
  final constellationRepository = ConstellationRepository();

  // Initialize astronomy engine and sensor service
  final astronomyEngine = AstronomyEngine(location: savedLocation);
  final orientationService = DeviceOrientationService();

  // Load saved calibration offset and sensor preferences
  if (preferencesService != null) {
    orientationService.setManualCalibrationOffset(
      preferencesService.loadHeadingOffset(),
    );
    orientationService.setInvertPitch(
      preferencesService.loadInvertPitch(),
    );
  }

  runApp(
    AstroTrackApp(
      starRepository: starRepository,
      constellationRepository: constellationRepository,
      astronomyEngine: astronomyEngine,
      orientationService: orientationService,
      preferencesService: preferencesService,
    ),
  );
}
