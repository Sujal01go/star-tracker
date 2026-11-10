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
    final savedHeadingOffset = preferencesService.loadHeadingOffset();
    // A 90°+ app trim is not a plausible local magnetic correction and can
    // rotate the tracked sky to the opposite direction. Discard legacy large
    // offsets so the device's north-referenced compass starts at its own heading.
    if (savedHeadingOffset.abs() < 90.0) {
      orientationService.setManualCalibrationOffset(savedHeadingOffset);
    } else {
      orientationService.setManualCalibrationOffset(0.0);
      await preferencesService.saveHeadingOffset(0.0);
    }
    orientationService.setInvertPitch(preferencesService.loadInvertPitch());
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
