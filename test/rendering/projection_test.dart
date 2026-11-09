import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/rendering/sky_projection.dart';

void main() {
  group('SkyProjection Tests', () {
    const viewport = Size(800.0, 600.0);

    test(
      'Object directly along camera gaze projects exactly to viewport center',
      () {
        const az = 180.0;
        const alt = 45.0;

        final projection = SkyProjection(
          centerAzimuth: az,
          centerAltitude: alt,
          fieldOfView: 60.0,
          viewportSize: viewport,
        );

        final screenPt = projection.projectCoordinates(az, alt);
        expect(screenPt, isNotNull);
        expect(screenPt!.dx, closeTo(400.0, 1e-4));
        expect(screenPt.dy, closeTo(300.0, 1e-4));
      },
    );

    test(
      'Object directly behind camera is strictly clipped (returns null)',
      () {
        final projection = SkyProjection(
          centerAzimuth: 0.0,
          centerAltitude: 0.0, // Camera facing North at horizon
          fieldOfView: 60.0,
          viewportSize: viewport,
        );

        // Star facing South at horizon (180° away)
        final screenPt = projection.projectCoordinates(180.0, 0.0);
        expect(screenPt, isNull);
      },
    );

    test(
      'Zooming in (narrower FOV) increases pixel separation of nearby stars',
      () {
        final wideProjection = SkyProjection(
          centerAzimuth: 90.0,
          centerAltitude: 30.0,
          fieldOfView: 90.0, // Wide angle
          viewportSize: viewport,
        );

        final teleProjection = SkyProjection(
          centerAzimuth: 90.0,
          centerAltitude: 30.0,
          fieldOfView: 30.0, // Narrow telephoto / zoom in
          viewportSize: viewport,
        );

        // Star 5° away in azimuth
        final ptWide = wideProjection.projectCoordinates(95.0, 30.0);
        final ptTele = teleProjection.projectCoordinates(95.0, 30.0);

        expect(ptWide, isNotNull);
        expect(ptTele, isNotNull);

        final offsetWide = (ptWide!.dx - 400.0).abs();
        final offsetTele = (ptTele!.dx - 400.0).abs();

        expect(offsetTele, greaterThan(offsetWide));
      },
    );

    test(
      'Unproject screen coordinates roundtrips to original sky position',
      () {
        const centerAz = 120.0;
        const centerAlt = 50.0;

        final projection = SkyProjection(
          centerAzimuth: centerAz,
          centerAltitude: centerAlt,
          fieldOfView: 60.0,
          viewportSize: viewport,
        );

        // Screen center unprojects to camera center
        final unprojected = projection.unprojectScreenCoordinates(
          const Offset(400.0, 300.0),
        );
        expect(unprojected, isNotNull);
        expect(unprojected!.azimuth, closeTo(centerAz, 1e-3));
        expect(unprojected.altitude, closeTo(centerAlt, 1e-3));
      },
    );
  });
}
