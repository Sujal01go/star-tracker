import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/data/constellation_repository.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/screens/solar_system_home_screen.dart';

void main() {
  testWidgets('SolarSystemHomeScreen renders header, planet pills, and cards', (
    tester,
  ) async {
    final astronomyEngine = AstronomyEngine();
    final starRepo = StarCatalogueRepository();
    final conRepo = ConstellationRepository();

    bool skyMapOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SolarSystemHomeScreen(
          astronomyEngine: astronomyEngine,
          starRepository: starRepo,
          constellationRepository: conRepo,
          onOpenSkyMap: () => skyMapOpened = true,
          onTrackPlanet: (_) {},
          onOpenTelescope: () {},
          onOpenDrawer: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Solar System'), findsWidgets);

    // Verify Planet Chips
    expect(find.text('Mercury'), findsOneWidget);
    expect(find.text('Venus'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Mars'), findsWidgets); // chip + card

    // Verify "Planet of the day" card
    expect(find.text('Planet of the day'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    // Tap 'Venus' chip to switch featured planet
    await tester.tap(find.text('Venus'));
    await tester.pumpAndSettle();

    // Venus should now be highlighted
    expect(find.text('Venus'), findsWidgets);

    // Verify "Explore in Sky Map" button
    final exploreBtn = find.text('Explore in Sky Map');
    expect(exploreBtn, findsOneWidget);
    await tester.ensureVisible(exploreBtn);
    await tester.tap(exploreBtn);
    expect(skyMapOpened, isTrue);
  });
}
