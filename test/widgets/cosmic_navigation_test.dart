import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/app/app.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/data/constellation_repository.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/sensors/device_orientation_service.dart';

void main() {
  testWidgets(
    'Cosmic navigation switches between Solar System, Search, and Telescope setup',
    (tester) async {
      final starRepo = StarCatalogueRepository();
      final conRepo = ConstellationRepository();
      final astronomyEngine = AstronomyEngine();
      final orientationService = DeviceOrientationService();

      await tester.pumpWidget(
        AstroTrackApp(
          starRepository: starRepo,
          constellationRepository: conRepo,
          astronomyEngine: astronomyEngine,
          orientationService: orientationService,
          initialTabIndex: 0,
        ),
      );

      await tester.pumpAndSettle();

      // Verify Tab 0 (Solar System) is active
      expect(find.text('Solar System'), findsWidgets);
      expect(find.text('Planet of the day'), findsOneWidget);

      // Sky Map interactions pause sensor tracking; opening the instruments
      // should resume it so both readouts continue updating together.
      orientationService.setManualCalibrationOffset(180.0);
      orientationService.processCompassData(0.0, accuracy: 15.0);
      orientationService.manualPan(deltaAzimuth: 1, deltaAltitude: 1);
      expect(orientationService.isTrackingActive, isFalse);

      // Switch to Tab 2: live observing search and recommendations
      final searchTab = find.text('Search');
      expect(searchTab, findsOneWidget);
      await tester.tap(searchTab);
      await tester.pumpAndSettle();

      expect(find.text('Explore the sky'), findsOneWidget);
      expect(find.text('Good targets right now'), findsOneWidget);

      // Switch to Tab 3: Telescope setup
      final telescopeTab = find.text('Telescope');
      expect(telescopeTab, findsOneWidget);
      await tester.tap(telescopeTab);
      await tester.pumpAndSettle();

      expect(find.text('Align your mount'), findsOneWidget);
      expect(find.text('Compass'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Before you observe'), findsOneWidget);
      expect(orientationService.isTrackingActive, isTrue);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('0°'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);

      expect(find.text('Match bearing'), findsNothing);
      expect(find.text('Align North'), findsNothing);
    },
  );

  testWidgets('App opens on Sky Map with device tracking enabled', (
    tester,
  ) async {
    final orientationService = DeviceOrientationService();

    await tester.pumpWidget(
      AstroTrackApp(
        starRepository: StarCatalogueRepository(),
        constellationRepository: ConstellationRepository(),
        astronomyEngine: AstronomyEngine(),
        orientationService: orientationService,
      ),
    );
    await tester.pumpAndSettle();

    expect(orientationService.isTrackingActive, isTrue);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });
}
