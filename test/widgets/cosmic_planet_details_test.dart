import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/models/planet.dart';
import 'package:astro_track/rendering/star_rendering_style.dart';
import 'package:astro_track/screens/star_details_screen.dart';

void main() {
  testWidgets('StarDetailsScreen renders 6 stat badges and CTA button for Earth', (
    tester,
  ) async {
    final astronomyEngine = AstronomyEngine();
    const earth = Planet(
      id: 'Earth',
      name: 'Earth',
      type: PlanetType.venus, // type for rendering
      symbol: '♁',
      rightAscension: 0.0,
      declination: 0.0,
      apparentMagnitude: -3.9,
      eclipticLongitude: 0.0,
      eclipticLatitude: 0.0,
      distanceAu: 1.0,
      illuminatedFraction: 1.0,
      phaseName: 'Full Disk',
      angularDiameterArcsec: 17.5,
      baseColor: Color(0xFF00E5FF),
    );

    bool trackTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StarDetailsScreen(
          planet: earth,
          astronomyEngine: astronomyEngine,
          style: const StarRenderingStyle(),
          onTrackPlanet: (_) => trackTriggered = true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Hero
    expect(find.text('Earth'), findsWidgets);

    // Verify 6 Key Specs from photo
    expect(find.text('5.97'), findsOneWidget); // Mass
    expect(find.text('9.8'), findsOneWidget); // Gravity
    expect(find.text('24'), findsOneWidget); // Day
    expect(find.text('11.2'), findsOneWidget); // Esc Vel
    expect(find.text('15°C'), findsOneWidget); // Mean Temp
    expect(find.text('149.6'), findsOneWidget); // Dist

    // Verify CTA button
    final ctaBtn = find.text('Visit Earth');
    expect(ctaBtn, findsOneWidget);
    await tester.ensureVisible(ctaBtn);
    await tester.tap(ctaBtn);
    expect(trackTriggered, isTrue);
  });
}
