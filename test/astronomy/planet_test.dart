import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/astronomy/planetary_ephemeris.dart';
import 'package:astro_track/data/constellation_repository.dart';
import 'package:astro_track/models/observer_location.dart';
import 'package:astro_track/models/observation_time.dart';
import 'package:astro_track/models/planet.dart';

void main() {
  group('PlanetaryEphemeris Solar Calculations', () {
    test('Sun coordinates near Vernal Equinox (March 20, 2000)', () {
      final equinoxDate = DateTime.utc(2000, 3, 20, 12, 0);
      final sun = PlanetaryEphemeris.computeSun(equinoxDate);

      // At vernal equinox, Sun RA is near 0° (or 360°) and Dec is near 0°
      expect(sun.type, PlanetType.sun);
      expect(sun.name, 'Sun');
      expect(sun.id, 'SUN');

      final ra = sun.rightAscension;
      final isNearZero = ra < 5.0 || ra > 355.0;
      expect(
        isNearZero,
        isTrue,
        reason: 'Sun RA at Vernal Equinox should be near 0°',
      );
      expect(sun.declination, closeTo(0.0, 1.5));
      expect(sun.apparentMagnitude, closeTo(-26.74, 0.1));
      expect(sun.distanceAu, closeTo(1.0, 0.02));
    });

    test('Sun coordinates near Summer Solstice (June 21, 2000)', () {
      final solsticeDate = DateTime.utc(2000, 6, 21, 12, 0);
      final sun = PlanetaryEphemeris.computeSun(solsticeDate);

      // At summer solstice, Sun RA is near 90° (6h) and Dec is near +23.44°
      expect(sun.rightAscension, closeTo(90.0, 3.0));
      expect(sun.declination, closeTo(23.44, 1.0));
    });

    test('Sun coordinates near Winter Solstice (December 21, 2000)', () {
      final solsticeDate = DateTime.utc(2000, 12, 21, 12, 0);
      final sun = PlanetaryEphemeris.computeSun(solsticeDate);

      // At winter solstice, Sun RA is near 270° (18h) and Dec is near -23.44°
      expect(sun.rightAscension, closeTo(270.0, 3.0));
      expect(sun.declination, closeTo(-23.44, 1.0));
    });
  });

  group('PlanetaryEphemeris Lunar Calculations', () {
    test('Moon produces realistic distance, diameter, and illumination', () {
      final now = DateTime.utc(2024, 5, 1, 0, 0);
      final moon = PlanetaryEphemeris.computeMoon(now);

      expect(moon.type, PlanetType.moon);
      expect(moon.id, 'MOON');
      expect(moon.symbol, '☽');

      // Moon distance ~ 360,000 to 405,000 km (0.0024 to 0.0027 AU)
      expect(moon.distanceMillionKm, inInclusiveRange(0.35, 0.42));
      expect(moon.distanceAu, inInclusiveRange(0.0023, 0.0028));

      // Angular diameter ~ 1800 arcseconds (30 arcminutes)
      expect(moon.angularDiameterArcsec, inInclusiveRange(1600.0, 2000.0));

      // Illumination fraction between 0.0 and 1.0
      expect(moon.illuminatedFraction, inInclusiveRange(0.0, 1.0));
      expect(moon.phaseName.isNotEmpty, isTrue);
    });

    test('Moon phase names match illuminated fractions', () {
      // Test known Full Moon date: Aug 19, 2024
      final fullMoonDate = DateTime.utc(2024, 8, 19, 18, 25);
      final moon = PlanetaryEphemeris.computeMoon(fullMoonDate);

      expect(moon.illuminatedFraction, greaterThan(0.90));
      expect(
        moon.phaseName.contains('Gibbous') || moon.phaseName.contains('Full'),
        isTrue,
      );
    });
  });

  group('PlanetaryEphemeris Major Planets Calculations', () {
    test(
      'computeAllPlanets returns 9 major Solar System bodies in Earth sky',
      () {
        final date = DateTime.utc(2024, 1, 1, 0, 0);
        final planets = PlanetaryEphemeris.computeAllPlanets(date);

        expect(planets.length, equals(10));

        final planetTypes = planets.map((p) => p.type).toSet();
        expect(planetTypes.contains(PlanetType.sun), isTrue);
        expect(planetTypes.contains(PlanetType.moon), isTrue);
        expect(planetTypes.contains(PlanetType.mercury), isTrue);
        expect(planetTypes.contains(PlanetType.venus), isTrue);
        expect(planetTypes.contains(PlanetType.mars), isTrue);
        expect(planetTypes.contains(PlanetType.jupiter), isTrue);
        expect(planetTypes.contains(PlanetType.saturn), isTrue);
        expect(planetTypes.contains(PlanetType.uranus), isTrue);
        expect(planetTypes.contains(PlanetType.neptune), isTrue);
        expect(planetTypes.contains(PlanetType.pluto), isTrue);
      },
    );

    test(
      'All major planets have physically valid coordinates and distances',
      () {
        final date = DateTime.utc(2025, 6, 15, 0, 0);
        final planets = PlanetaryEphemeris.computeAllPlanets(date);

        for (final planet in planets) {
          // RA in [0, 360)
          expect(
            planet.rightAscension,
            inInclusiveRange(0.0, 360.0),
            reason: '${planet.name} RA out of range',
          );

          // Declination in [-90, +90]
          expect(
            planet.declination,
            inInclusiveRange(-90.0, 90.0),
            reason: '${planet.name} Dec out of range',
          );

          // Earth-distance must be strictly positive
          expect(
            planet.distanceAu,
            greaterThan(0.0),
            reason: '${planet.name} distance must be positive',
          );

          // Apparent magnitude must be plausible
          expect(
            planet.apparentMagnitude,
            inInclusiveRange(-30.0, 15.0),
            reason: '${planet.name} magnitude out of range',
          );

          // Symbol must be a valid astronomical character
          expect(planet.symbol.isNotEmpty, isTrue);
        }
      },
    );

    test('Jupiter and Saturn distances are realistic planetary scale', () {
      final date = DateTime.utc(2024, 10, 15, 0, 0);
      final planets = PlanetaryEphemeris.computeAllPlanets(date);

      final jupiter = planets.firstWhere((p) => p.type == PlanetType.jupiter);
      final saturn = planets.firstWhere((p) => p.type == PlanetType.saturn);

      // Jupiter is typically 3.9 to 6.5 AU from Earth
      expect(jupiter.distanceAu, inInclusiveRange(3.8, 6.6));
      expect(jupiter.apparentMagnitude, inInclusiveRange(-3.0, -1.5));

      // Saturn is typically 8.0 to 11.0 AU from Earth
      expect(saturn.distanceAu, inInclusiveRange(7.5, 11.5));
      expect(saturn.apparentMagnitude, inInclusiveRange(-0.5, 1.8));
    });
  });

  group('AstronomyEngine Planetary Integration', () {
    test('Engine computes local horizontal coordinates for all planets', () {
      final engine = AstronomyEngine(
        location: ObserverLocation.greenwich,
        time: ObservationTime(
          utcDateTime: DateTime.utc(2024, 6, 21, 22, 0),
          isRealTime: false,
        ),
      );

      expect(engine.planets.length, equals(10));
      expect(engine.planetPositions.length, equals(10));

      final jupiter = engine.getPlanetById('JUPITER');
      expect(jupiter, isNotNull);
      expect(jupiter!.name, 'Jupiter');

      final jupiterPos = engine.planetPositions[jupiter.id];
      expect(jupiterPos, isNotNull);
      expect(jupiterPos!.azimuth, inInclusiveRange(0.0, 360.0));
      expect(jupiterPos.altitude, inInclusiveRange(-90.0, 90.0));
    });

    test('Updating observation time updates planet positions', () {
      final engine = AstronomyEngine(
        location: ObserverLocation.greenwich,
        time: ObservationTime(
          utcDateTime: DateTime.utc(2024, 3, 20, 12, 0), // Midday
          isRealTime: false,
        ),
      );

      final sunMidday = engine.planetPositions['SUN']!;
      expect(
        sunMidday.altitude,
        greaterThan(35.0),
        reason: 'Sun should be high at noon in March',
      );

      // Fast-forward 12 hours to midnight
      engine.updateTime(
        ObservationTime(
          utcDateTime: DateTime.utc(2024, 3, 20, 0, 0), // Midnight
          isRealTime: false,
        ),
      );

      final sunMidnight = engine.planetPositions['SUN']!;
      expect(
        sunMidnight.altitude,
        lessThan(-30.0),
        reason: 'Sun should be well below horizon at midnight',
      );
    });
  });

  group('Additional Solar System Ephemerides', () {
    test('Includes dynamically propagated minor bodies and Galilean moons', () {
      final firstDate = DateTime.utc(2026, 6, 10, 0, 0);
      final nextDate = DateTime.utc(2026, 6, 11, 0, 0);
      final first = PlanetaryEphemeris.computeAdditionalBodies(firstDate);
      final next = PlanetaryEphemeris.computeAdditionalBodies(nextDate);

      expect(first, hasLength(12));
      expect(
        first.map((body) => body.id),
        containsAll([
          'CER',
          'VES',
          'PAL',
          'JUN',
          'ERI',
          'HAU',
          'MAK',
          'HALLEY',
          'IO',
          'EUROPA',
          'GANYMEDE',
          'CALLISTO',
        ]),
      );
      for (final body in first) {
        expect(body.distanceAu, greaterThan(0));
        expect(body.rightAscension, inInclusiveRange(0, 360));
        expect(body.declination, inInclusiveRange(-90, 90));
        expect(body.ephemerisSource, isNotNull);
      }

      final firstIo = first.firstWhere((body) => body.id == 'IO');
      final nextIo = next.firstWhere((body) => body.id == 'IO');
      expect(
        (firstIo.rightAscension - nextIo.rightAscension).abs() +
            (firstIo.declination - nextIo.declination).abs(),
        greaterThan(0.0001),
        reason: 'A Galilean moon position must change with observation time.',
      );
    });

    test('Keeps the original major-planet API while indexing extra bodies', () {
      final engine = AstronomyEngine(
        location: ObserverLocation.greenwich,
        time: ObservationTime(
          utcDateTime: DateTime.utc(2026, 6, 10),
          isRealTime: false,
        ),
      );

      expect(engine.planets, hasLength(10));
      expect(engine.planetPositions, hasLength(10));
      expect(engine.additionalBodies, hasLength(12));
      expect(engine.additionalBodyPositions, hasLength(12));
      expect(engine.solarSystemPositions, hasLength(22));
      expect(engine.getPlanetById('Ceres')?.id, 'CER');

      final ceresBefore = engine.solarSystemPositions['CER']!;
      engine.updateTime(
        ObservationTime(
          utcDateTime: DateTime.utc(2026, 7, 10),
          isRealTime: false,
        ),
      );
      final ceresAfter = engine.solarSystemPositions['CER']!;
      expect(ceresBefore.azimuth, isNot(ceresAfter.azimuth));
    });
  });

  group('ConstellationRepository 88 Constellations Integrity', () {
    test(
      'loadConstellations parses all 88 official IAU constellations',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final repo = ConstellationRepository();
        await repo.loadConstellations();

        expect(repo.isLoaded, isTrue);
        expect(repo.allConstellations.length, equals(88));

        // Spot-check iconic constellations
        final orion = repo.getConstellationById('ORI');
        expect(orion, isNotNull);
        expect(orion?.name, 'Orion');
        expect(orion?.englishName, 'The Hunter');
        expect(orion?.lines.isNotEmpty, isTrue);

        final ursaMajor = repo.getConstellationById('UMA');
        expect(ursaMajor, isNotNull);
        expect(ursaMajor?.name, 'Ursa Major');

        final crux = repo.getConstellationById('CRU');
        expect(crux, isNotNull);
        expect(crux?.name, 'Crux');

        final cassiopeia = repo.getConstellationById('CAS');
        expect(cassiopeia, isNotNull);
        expect(cassiopeia?.name, 'Cassiopeia');

        final scorpius = repo.getConstellationById('SCO');
        expect(scorpius, isNotNull);
        expect(scorpius?.name, 'Scorpius');
      },
    );
  });
}
