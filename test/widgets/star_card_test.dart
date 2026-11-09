import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/models/sky_position.dart';
import 'package:astro_track/models/star.dart';
import 'package:astro_track/rendering/star_rendering_style.dart';
import 'package:astro_track/widgets/star_information_card.dart';

void main() {
  testWidgets(
    'StarInformationCard displays star properties and triggers center button',
    (tester) async {
      const star = Star(
        id: 'HIP 32349',
        commonName: 'Sirius',
        bayerDesignation: 'Alpha CMa',
        constellationId: 'CMa',
        rightAscension: 101.287,
        declination: -16.716,
        apparentMagnitude: -1.46,
        spectralType: 'A1V',
      );

      const position = SkyPosition(azimuth: 145.2, altitude: 32.8);

      bool centerClicked = false;
      bool detailsClicked = false;
      bool closeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarInformationCard(
              star: star,
              position: position,
              style: const StarRenderingStyle(),
              onCenterView: () => centerClicked = true,
              onFullDetails: () => detailsClicked = true,
              onClose: () => closeClicked = true,
            ),
          ),
        ),
      );

      // Verify Star Name and IDs are rendered
      expect(find.text('Sirius'), findsOneWidget);
      expect(find.textContaining('HIP 32349'), findsOneWidget);
      expect(find.text('-1.46'), findsOneWidget);
      expect(find.text('A1V'), findsOneWidget);
      expect(find.text('32.8°'), findsOneWidget);

      // Verify Action buttons
      final centerBtn = find.text('Center Map');
      expect(centerBtn, findsOneWidget);
      await tester.tap(centerBtn);
      expect(centerClicked, isTrue);

      final detailsBtn = find.text('Full Details');
      expect(detailsBtn, findsOneWidget);
      await tester.tap(detailsBtn);
      expect(detailsClicked, isTrue);

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(closeClicked, isTrue);
    },
  );
}
