import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/models/constellation.dart';
import 'package:astro_track/models/deep_sky_object.dart';
import 'package:astro_track/models/sky_position.dart';
import 'package:astro_track/models/star.dart';
import 'package:astro_track/rendering/sky_projection.dart';
import 'package:astro_track/rendering/star_map_painter.dart';
import 'package:astro_track/rendering/star_rendering_style.dart';
import 'package:astro_track/services/constellation_asset_service.dart';

void main() {
  group('Star Decluttering & Famous Stars Tests', () {
    const famousStar1 = Star(
      id: 'HIP 32349',
      commonName: 'Sirius',
      bayerDesignation: 'Alpha CMa',
      rightAscension: 101.28,
      declination: -16.71,
      apparentMagnitude: -1.46,
    );

    const famousStar2 = Star(
      id: 'HIP 11767',
      commonName: 'Polaris',
      bayerDesignation: 'Alpha UMi',
      rightAscension: 37.95,
      declination: 89.26,
      apparentMagnitude: 1.97,
    );

    const faintStar = Star(
      id: 'HIP 99999',
      name: 'Faint Star',
      bayerDesignation: 'Nu Oct',
      rightAscension: 180.0,
      declination: 45.0,
      apparentMagnitude: 4.85,
    );

    test('isFamous correctly categorizes prominent vs faint stars', () {
      expect(famousStar1.isFamous, isTrue);
      expect(famousStar2.isFamous, isTrue);
      expect(faintStar.isFamous, isFalse);
    });

    test(
      'StarMapPainter hides least famous stars by default unless selected',
      () {
        final projection = SkyProjection(
          centerAzimuth: 180.0,
          centerAltitude: 45.0,
          fieldOfView: 100.0,
          viewportSize: const Size(800, 600),
        );

        final stars = [famousStar1, faintStar];
        final starPositions = {
          famousStar1.id: const SkyPosition(azimuth: 180.0, altitude: 45.0),
          faintStar.id: const SkyPosition(azimuth: 180.0, altitude: 45.0),
        };

        Map<String, Offset>? reportedOffsets;

        // 1. With hideLeastFamousStars = true and nothing selected
        final painterDecluttered = StarMapPainter(
          stars: stars,
          starPositions: starPositions,
          constellations: const [],
          projection: projection,
          style: const StarRenderingStyle(hideLeastFamousStars: true),
          onRenderedPositions: (offsets) => reportedOffsets = offsets,
        );

        // Paint to trigger onRenderedPositions
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painterDecluttered.paint(canvas, const Size(800, 600));

        // Famous star is rendered, faint star is hidden!
        expect(reportedOffsets!.containsKey(famousStar1.id), isTrue);
        expect(reportedOffsets!.containsKey(faintStar.id), isFalse);

        // 2. When faint star is explicitly selected (e.g. from search)
        final painterSelected = StarMapPainter(
          stars: stars,
          starPositions: starPositions,
          constellations: const [],
          projection: projection,
          style: const StarRenderingStyle(hideLeastFamousStars: true),
          selectedStarId: faintStar.id,
          onRenderedPositions: (offsets) => reportedOffsets = offsets,
        );

        painterSelected.paint(canvas, const Size(800, 600));

        // Now the selected faint star IS rendered!
        expect(reportedOffsets!.containsKey(faintStar.id), isTrue);
      },
    );

    test('ConstellationAssetService maps constellation codes to artwork', () {
      expect(
        ConstellationAssetService.getArtworkForConstellation('Ori'),
        contains('orion.png'),
      );
      expect(
        ConstellationAssetService.getArtworkForConstellation('Ursa Major'),
        contains('ursa_major.png'),
      );
      expect(
        ConstellationAssetService.getArtworkForConstellation('GEM'),
        contains('gemini.png'),
      );
      expect(
        ConstellationAssetService.getArtworkForConstellation('CRU'),
        contains('crux.png'),
      );
      expect(ConstellationAssetService.hasArtwork('ORI'), isTrue);
      expect(ConstellationAssetService.hasArtwork('UNKNOWN'), isFalse);
      expect(
        ConstellationAssetService.getArtworkForConstellation('UNKNOWN'),
        contains('default_constellation.png'),
      );
    });

    test('Faint constellation members are not automatically famous', () {
      const casStar = Star(
        id: 'HIP 6537',
        name: 'Ruchbah',
        commonName: 'Ruchbah',
        constellationId: 'Cas',
        rightAscension: 20.0,
        declination: 60.0,
        apparentMagnitude: 2.68,
      );
      expect(casStar.isFamous, isFalse);
    });

    test('faint stars and extended targets appear as the field narrows', () {
      const position = SkyPosition(azimuth: 180, altitude: 45);
      const faintFieldStar = Star(
        id: 'HIP 99999',
        name: 'Faint Field Star',
        rightAscension: 180,
        declination: 45,
        apparentMagnitude: 4.85,
      );
      const orionNebula = DeepSkyObject(
        id: 'M42',
        name: 'Orion Nebula',
        catalogueIdentifiers: ['M42'],
        objectType: 'Nebula',
        rightAscension: 83.82,
        declination: -5.39,
        apparentMagnitude: 4.0,
        angularSizeMajorArcminutes: 85,
        description: 'Emission nebula.',
        visibilityClass: 'bright',
        source: 'test',
      );
      const cygnusRift = DeepSkyObject(
        id: 'Cygnus Rift',
        name: 'Cygnus Rift',
        catalogueIdentifiers: ['NAME Cygnus Rift'],
        objectType: 'Dark nebula',
        rightAscension: 305.25,
        declination: 37,
        angularSizeMajorArcminutes: 1410,
        angularSizeMinorArcminutes: 480,
        description: 'Dark molecular cloud.',
        visibilityClass: 'feature',
        source: 'SIMBAD',
      );

      Map<String, Offset> renderAtFov(double fieldOfView) {
        Map<String, Offset> offsets = {};
        final painter = StarMapPainter(
          stars: const [faintFieldStar],
          starPositions: const {'HIP 99999': position},
          constellations: const [],
          deepSkyObjects: const [orionNebula, cygnusRift],
          deepSkyPositions: const {'M42': position, 'Cygnus Rift': position},
          projection: SkyProjection(
            centerAzimuth: 180,
            centerAltitude: 45,
            fieldOfView: fieldOfView,
            viewportSize: const Size(800, 600),
          ),
          style: const StarRenderingStyle(
            showConstellationLines: false,
            showConstellationNames: false,
            showConstellationArt: false,
            showCelestialGrid: false,
            showHorizon: false,
            showStarLabels: false,
          ),
          onRenderedPositions: (rendered) => offsets = rendered,
        );
        painter.paint(Canvas(ui.PictureRecorder()), const Size(800, 600));
        return offsets;
      }

      final wideField = renderAtFov(100);
      expect(wideField, isNot(contains('HIP 99999')));
      expect(wideField, isNot(contains('M42')));
      expect(wideField, isNot(contains('Cygnus Rift')));

      final closeUp = renderAtFov(35);
      expect(closeUp, contains('HIP 99999'));
      expect(closeUp, contains('M42'));
      expect(closeUp, contains('Cygnus Rift'));
    });

    test('StarMapPainter caches constellation position in renderedOffsets', () {
      final projection = SkyProjection(
        centerAzimuth: 180.0,
        centerAltitude: 45.0,
        fieldOfView: 60.0,
        viewportSize: const Size(800, 600),
      );

      const constellation = Constellation(
        id: 'ORI',
        name: 'Orion',
        englishName: 'The Hunter',
        centerRa: 83.8,
        centerDec: -5.4,
        lines: [],
      );

      final constellationPositions = {
        'ORI': const SkyPosition(azimuth: 180.0, altitude: 45.0),
      };

      Map<String, Offset>? reportedOffsets;

      final painter = StarMapPainter(
        stars: const [],
        starPositions: const {},
        constellations: const [constellation],
        constellationPositions: constellationPositions,
        projection: projection,
        style: const StarRenderingStyle(showConstellationArt: true),
        onRenderedPositions: (offsets) => reportedOffsets = offsets,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));

      expect(reportedOffsets, isNotNull);
      // Constellation position is recorded for reticle and hit testing
      expect(reportedOffsets!.containsKey('ORI'), isTrue);
    });
  });
}
