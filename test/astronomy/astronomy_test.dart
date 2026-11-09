import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomical_time.dart';
import 'package:astro_track/astronomy/coordinate_transform.dart';
import 'package:astro_track/astronomy/sidereal_time.dart';
import 'package:astro_track/astronomy/spherical_geometry.dart';
import 'package:astro_track/models/observer_location.dart';
import 'package:astro_track/models/observation_time.dart';
import 'package:astro_track/models/star.dart';
import 'package:astro_track/astronomy/star_position_calculator.dart';

void main() {
  group('SphericalGeometry Tests', () {
    test(
      'normalizeDegrees360 handles positive, negative, and wrapping values',
      () {
        expect(SphericalGeometry.normalizeDegrees360(0.0), closeTo(0.0, 1e-9));
        expect(
          SphericalGeometry.normalizeDegrees360(360.0),
          closeTo(0.0, 1e-9),
        );
        expect(
          SphericalGeometry.normalizeDegrees360(725.5),
          closeTo(5.5, 1e-9),
        );
        expect(
          SphericalGeometry.normalizeDegrees360(-10.0),
          closeTo(350.0, 1e-9),
        );
        expect(
          SphericalGeometry.normalizeDegrees360(-370.0),
          closeTo(350.0, 1e-9),
        );
      },
    );

    test('normalizeDegrees180 wraps angles correctly into [-180, +180]', () {
      expect(SphericalGeometry.normalizeDegrees180(0.0), closeTo(0.0, 1e-9));
      expect(
        SphericalGeometry.normalizeDegrees180(180.0),
        closeTo(180.0, 1e-9),
      );
      expect(
        SphericalGeometry.normalizeDegrees180(190.0),
        closeTo(-170.0, 1e-9),
      );
      expect(
        SphericalGeometry.normalizeDegrees180(-190.0),
        closeTo(170.0, 1e-9),
      );
      expect(SphericalGeometry.normalizeDegrees180(359.0), closeTo(-1.0, 1e-9));
    });

    test('horizontalToUnitVector and unitVectorToHorizontal round-trip', () {
      // North horizon
      final vNorth = SphericalGeometry.horizontalToUnitVector(0.0, 0.0);
      expect(vNorth.x, closeTo(0.0, 1e-9)); // East
      expect(vNorth.y, closeTo(1.0, 1e-9)); // North
      expect(vNorth.z, closeTo(0.0, 1e-9)); // Zenith

      // East horizon
      final vEast = SphericalGeometry.horizontalToUnitVector(90.0, 0.0);
      expect(vEast.x, closeTo(1.0, 1e-9));
      expect(vEast.y, closeTo(0.0, 1e-9));

      // Zenith
      final vZenith = SphericalGeometry.horizontalToUnitVector(0.0, 90.0);
      expect(vZenith.z, closeTo(1.0, 1e-9));

      // General point roundtrip
      final origAz = 142.5;
      final origAlt = 37.8;
      final vec = SphericalGeometry.horizontalToUnitVector(origAz, origAlt);
      final res = SphericalGeometry.unitVectorToHorizontal(vec);
      expect(res.azimuth, closeTo(origAz, 1e-5));
      expect(res.altitude, closeTo(origAlt, 1e-5));
    });

    test('North-crossing angular distance', () {
      // From 359° to 1° along equator is 2° separation
      final dist = SphericalGeometry.angularDistance(359.0, 0.0, 1.0, 0.0);
      expect(dist, closeTo(2.0, 1e-5));
    });
  });

  group('AstronomicalTime & Julian Date Tests', () {
    test(
      'Julian Date for J2000.0 epoch (2000-01-01 12:00:00 UTC) is exactly 2451545.0',
      () {
        final j2000Utc = DateTime.utc(2000, 1, 1, 12, 0, 0);
        final jd = AstronomicalTime.julianDate(j2000Utc);
        expect(jd, closeTo(2451545.0, 1e-6));
        expect(AstronomicalTime.julianCenturiesJ2000(jd), closeTo(0.0, 1e-8));
      },
    );

    test(
      'Julian Date for standard reference date (1957-10-04 19:26:24 Sputnik)',
      () {
        final sputnikUtc = DateTime.utc(1957, 10, 4, 19, 26, 24);
        final jd = AstronomicalTime.julianDate(sputnikUtc);
        // Known astronomical benchmark: 2436116.31
        expect(jd, closeTo(2436116.31, 0.01));
      },
    );

    test('Julian Date roundtrip through dateTimeFromJulianDate', () {
      final original = DateTime.utc(2026, 10, 30, 20, 15, 30);
      final jd = AstronomicalTime.julianDate(original);
      final recovered = AstronomicalTime.dateTimeFromJulianDate(jd);

      expect(recovered.year, equals(original.year));
      expect(recovered.month, equals(original.month));
      expect(recovered.day, equals(original.day));
      expect(recovered.hour, equals(original.hour));
      expect(recovered.minute, equals(original.minute));
      expect(recovered.second, equals(original.second));
    });
  });

  group('SiderealTime Tests', () {
    test('GMST at J2000.0 epoch is ~280.4606 degrees (18.697 hours)', () {
      final jd = 2451545.0;
      final gmstDeg = SiderealTime.greenwichMeanSiderealTime(jd);
      expect(gmstDeg, closeTo(280.46061837, 1e-5));

      final gmstHours = SiderealTime.greenwichMeanSiderealTimeHours(jd);
      expect(gmstHours, closeTo(18.6973745, 1e-5));
    });

    test(
      'Local Sidereal Time accounts for East-positive longitude convention',
      () {
        const gmstDeg = 100.0;
        // 30° East longitude => LST = 130°
        expect(
          SiderealTime.localSiderealTime(gmstDeg, 30.0),
          closeTo(130.0, 1e-6),
        );
        // 30° West longitude (-30°) => LST = 70°
        expect(
          SiderealTime.localSiderealTime(gmstDeg, -30.0),
          closeTo(70.0, 1e-6),
        );
        // 300° East => 400° % 360 = 40°
        expect(
          SiderealTime.localSiderealTime(gmstDeg, 300.0),
          closeTo(40.0, 1e-6),
        );
      },
    );

    test('Hour Angle H = LST - RA', () {
      expect(SiderealTime.hourAngleDegrees(150.0, 50.0), closeTo(100.0, 1e-6));
      expect(SiderealTime.hourAngleDegrees(50.0, 150.0), closeTo(260.0, 1e-6));
      expect(
        SiderealTime.hourAngleSignedDegrees(50.0, 150.0),
        closeTo(-100.0, 1e-6),
      );
    });
  });

  group('CoordinateTransform & Analytical Edge Cases', () {
    test(
      'Analytical Test: Observer Lat=30°, Star Dec=30°, H=0° gives Altitude=90° (Zenith)',
      () {
        // sin(alt) = sin(30)*sin(30) + cos(30)*cos(30)*cos(0) = 0.25 + 0.75 = 1.0 => alt = 90.0°
        final pos = CoordinateTransform.equatorialToHorizontal(
          raDeg: 100.0,
          decDeg: 30.0,
          latitudeDeg: 30.0,
          lstDeg: 100.0, // H = 0.0
        );

        expect(pos.altitude, closeTo(90.0, 1e-6));
        // At zenith, azimuth is geometrically degenerate. The API must handle this gracefully without NaN.
        expect(pos.azimuth.isNaN, isFalse);
        expect(pos.altitude.isNaN, isFalse);
      },
    );

    test(
      'Equatorial to Horizontal: Star on Celestial Equator transiting South at Lat=45°',
      () {
        // Dec = 0°, Lat = 45°N, H = 0° (transit).
        // Altitude = 90° - 45° = 45.0°, Azimuth = 180.0° (South).
        final pos = CoordinateTransform.equatorialToHorizontal(
          raDeg: 60.0,
          decDeg: 0.0,
          latitudeDeg: 45.0,
          lstDeg: 60.0, // H = 0.0
        );

        expect(pos.altitude, closeTo(45.0, 1e-5));
        expect(pos.azimuth, closeTo(180.0, 1e-5));
      },
    );

    test('Polaris near North Celestial Pole (Dec = 89.26°)', () {
      // For an observer at latitude 50°N, Polaris should stay within ~1° of altitude 50° and azimuth near 0° or 360°
      final pos1 = CoordinateTransform.equatorialToHorizontal(
        raDeg: 37.95,
        decDeg: 89.26,
        latitudeDeg: 50.0,
        lstDeg: 37.95, // Upper culmination
      );
      expect(pos1.altitude, closeTo(50.74, 0.1));
      final azDev1 = math.min(pos1.azimuth, (360.0 - pos1.azimuth).abs());
      expect(azDev1, lessThan(2.0)); // Near North

      final pos2 = CoordinateTransform.equatorialToHorizontal(
        raDeg: 37.95,
        decDeg: 89.26,
        latitudeDeg: 50.0,
        lstDeg: 37.95 + 180.0, // Lower culmination
      );
      expect(pos2.altitude, closeTo(49.26, 0.1));
      final azDev2 = math.min(pos2.azimuth, (360.0 - pos2.azimuth).abs());
      expect(azDev2, lessThan(2.0)); // Near North
    });

    test(
      'Star below horizon correctly reports negative altitude and isVisible = false',
      () {
        // Star in southern sky for a northern observer
        final pos = CoordinateTransform.equatorialToHorizontal(
          raDeg: 0.0,
          decDeg: -60.0,
          latitudeDeg: 50.0,
          lstDeg: 180.0, // Anti-transit
        );

        expect(pos.altitude, lessThan(0.0));
        expect(pos.isVisible, isFalse);
      },
    );

    test('Equatorial <-> Horizontal roundtrip transformation', () {
      const lat = 35.6895; // Tokyo
      const lst = 85.0;
      const originalRa = 45.0;
      const originalDec = 28.0;

      final horiz = CoordinateTransform.equatorialToHorizontal(
        raDeg: originalRa,
        decDeg: originalDec,
        latitudeDeg: lat,
        lstDeg: lst,
      );

      final recovered = CoordinateTransform.horizontalToEquatorial(
        azimuthDeg: horiz.azimuth,
        altitudeDeg: horiz.altitude,
        latitudeDeg: lat,
        lstDeg: lst,
      );

      expect(recovered.rightAscension, closeTo(originalRa, 1e-4));
      expect(recovered.declination, closeTo(originalDec, 1e-4));
    });

    test(
      'Atmospheric refraction adds positive elevation near horizon and zero far above',
      () {
        final horizonAlt = 0.0;
        final refracted = CoordinateTransform.addAtmosphericRefraction(
          horizonAlt,
        );
        // Bennett formula at 0° gives ~34 arcminutes (~0.57 degrees) of refraction
        expect(refracted, closeTo(0.57, 0.1));

        // At zenith (90°), refraction is near zero
        final zenithRefracted = CoordinateTransform.addAtmosphericRefraction(
          90.0,
        );
        expect(zenithRefracted - 90.0, closeTo(0.0, 1e-3));
      },
    );
  });

  group('StarPositionCalculator & Precession Tests', () {
    test('Calculates Sirius (Alpha CMa) position accurately', () {
      // Sirius: RA = 101.287° (06h 45m 09s), Dec = -16.716°
      const sirius = Star(
        id: 'HIP 32349',
        commonName: 'Sirius',
        bayerDesignation: 'Alpha CMa',
        rightAscension: 101.287,
        declination: -16.716,
        apparentMagnitude: -1.46,
        spectralType: 'A1V',
      );

      final location = ObserverLocation.greenwich;
      final time = ObservationTime(
        utcDateTime: DateTime.utc(2026, 1, 15, 22, 0, 0),
      );

      final pos = StarPositionCalculator.computePosition(
        star: sirius,
        location: location,
        time: time,
        applyPrecession: true,
      );

      expect(pos.altitude.isNaN, isFalse);
      expect(pos.azimuth.isNaN, isFalse);
      expect(pos.azimuth, inInclusiveRange(0.0, 360.0));
      expect(pos.altitude, inInclusiveRange(-90.0, 90.0));
    });

    test(
      'Batch computation produces consistent results with individual calculation',
      () {
        final stars = [
          const Star(
            id: 'S1',
            rightAscension: 10.0,
            declination: 20.0,
            apparentMagnitude: 1.0,
          ),
          const Star(
            id: 'S2',
            rightAscension: 150.0,
            declination: -30.0,
            apparentMagnitude: 2.0,
          ),
          const Star(
            id: 'S3',
            rightAscension: 280.0,
            declination: 75.0,
            apparentMagnitude: 0.5,
          ),
        ];

        final loc = ObserverLocation.newDelhi;
        final time = ObservationTime.now();

        final batch = StarPositionCalculator.computeBatchPositions(
          stars: stars,
          location: loc,
          time: time,
        );

        for (final s in stars) {
          final individual = StarPositionCalculator.computePosition(
            star: s,
            location: loc,
            time: time,
            applyRefraction: false,
          );
          expect(batch[s.id]!.altitude, closeTo(individual.altitude, 1e-4));
          expect(batch[s.id]!.azimuth, closeTo(individual.azimuth, 1e-4));
        }
      },
    );
  });
}
