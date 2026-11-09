import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/data/default_constellations_data.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/rendering/sky_projection.dart';

void main() {
  group('Catalogue & Positioning Integrity Tests', () {
    test(
      'All star IDs in catalogue are strictly unique with zero collisions',
      () {
        final repo = StarCatalogueRepository();
        final allStars = repo.allStars;
        expect(allStars.isNotEmpty, isTrue);

        final idSet = <String>{};
        for (final star in allStars) {
          expect(
            idSet.contains(star.id),
            isFalse,
            reason: 'Duplicate star ID found: ${star.id} (${star.commonName})',
          );
          idSet.add(star.id);
        }
      },
    );

    test(
      'Altair, Fawaris, and Albireo have distinct and accurate coordinates',
      () {
        final repo = StarCatalogueRepository();
        final altair = repo.getStarById('HIP 97649');
        final fawaris = repo.getStarById('HIP 97165');
        final albireo = repo.getStarById('HIP 95947');

        expect(altair, isNotNull);
        expect(fawaris, isNotNull);
        expect(albireo, isNotNull);

        // Altair should be in Aquila at Dec ~8.87°
        expect(altair!.constellationId, equals('Aql'));
        expect(altair.declination, closeTo(8.87, 0.5));

        // Fawaris should be in Cygnus at Dec ~45.13°
        expect(fawaris!.constellationId, equals('Cyg'));
        expect(fawaris.declination, closeTo(45.13, 0.5));

        // Albireo should be in Cygnus at Dec ~27.96°
        expect(albireo!.constellationId, equals('Cyg'));
        expect(albireo.declination, closeTo(27.96, 0.5));
      },
    );

    test('All constellation lines reference existing stars in catalogue', () {
      final repo = StarCatalogueRepository();
      final List<dynamic> consList =
          jsonDecode(all88ConstellationsJson) as List<dynamic>;

      int totalLines = 0;
      for (final con in consList) {
        final lines = (con['lines'] as List).cast<List>();
        for (final line in lines) {
          totalLines++;
          final star1 = repo.getStarById(line[0].toString());
          final star2 = repo.getStarById(line[1].toString());

          expect(
            star1,
            isNotNull,
            reason: 'Missing star ${line[0]} in constellation ${con['id']}',
          );
          expect(
            star2,
            isNotNull,
            reason: 'Missing star ${line[1]} in constellation ${con['id']}',
          );
        }
      }
      expect(totalLines, greaterThan(150));
    });

    test(
      'SkyProjection right-vector remains smooth and continuous through Zenith',
      () {
        final p89 = SkyProjection(
          centerAzimuth: 0.0,
          centerAltitude: 89.9,
          fieldOfView: 60.0,
          viewportSize: const Size(1080, 2400),
        );

        final p90 = SkyProjection(
          centerAzimuth: 0.0,
          centerAltitude: 90.0,
          fieldOfView: 60.0,
          viewportSize: const Size(1080, 2400),
        );

        // Object at Az=0, Alt=89.9 projected on both
        final pt89 = p89.projectCoordinates(0.0, 89.9);
        final pt90 = p90.projectCoordinates(0.0, 89.9);

        expect(pt89, isNotNull);
        expect(pt90, isNotNull);
        expect((pt89!.dx - pt90!.dx).abs(), lessThan(0.01));
        // 0.1° elevation difference across focal length produces ~1.63px
        expect((pt89.dy - pt90.dy).abs(), lessThan(3.0));
      },
    );
  });
}
