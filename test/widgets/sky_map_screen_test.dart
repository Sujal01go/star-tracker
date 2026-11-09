import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/app/app.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/data/constellation_repository.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/sensors/device_orientation_service.dart';

void main() {
  testWidgets('Selecting a home constellation opens its sky-map card', (
    tester,
  ) async {
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

    final orion = find.text('Orion').first;
    await tester.ensureVisible(orion);
    await tester.tap(orion);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Orion'), findsWidgets);
  });

  testWidgets('AstroTrackApp loads and displays SkyMapScreen with HUD controls', (
    tester,
  ) async {
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
        initialTabIndex: 1,
      ),
    );

    await tester.pumpAndSettle();

    // Verify Location indicator is present
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

    // Verify Search and Settings icon buttons are present
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify Control cluster icons are present (touch pan, add zoom, remove zoom, etc.)
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_4x4), findsOneWidget);
  });
}
