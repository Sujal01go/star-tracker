import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/planet.dart';
import 'astronomical_time.dart';
import 'coordinate_transform.dart';
import 'spherical_geometry.dart';

/// Keplerian orbital element set for a planet at a specific epoch.
class _KeplerianElements {
  final double a; // Semi-major axis in AU
  final double e; // Eccentricity
  final double i; // Inclination in degrees
  final double l; // Mean longitude in degrees
  final double w; // Longitude of perihelion in degrees
  final double node; // Longitude of ascending node in degrees

  const _KeplerianElements({
    required this.a,
    required this.e,
    required this.i,
    required this.l,
    required this.w,
    required this.node,
  });
}

class _OsculatingBody {
  final String id;
  final String name;
  final PlanetType type;
  final String symbol;
  final double a;
  final double e;
  final double i;
  final double node;
  final double argumentOfPerihelion;
  final double meanAnomaly;
  final double epochJd;
  final double absoluteMagnitude;
  final double slopeParameter;
  final double diameterKm;
  final Color color;
  final String source;
  final String description;
  final bool isComet;

  const _OsculatingBody({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.a,
    required this.e,
    required this.i,
    required this.node,
    required this.argumentOfPerihelion,
    required this.meanAnomaly,
    required this.epochJd,
    required this.absoluteMagnitude,
    this.slopeParameter = 0.15,
    required this.diameterKm,
    required this.color,
    required this.source,
    required this.description,
    this.isComet = false,
  });
}

class _GalileanOrbit {
  final String id;
  final String name;
  final String symbol;
  final double semiMajorAxisKm;
  final double eccentricity;
  final double inclination;
  final double ascendingNode;
  final double argumentOfPeriapsis;
  final double meanAnomaly;
  final double periodDays;
  final double magnitudeAtOpposition;
  final double diameterKm;
  final Color color;

  const _GalileanOrbit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.semiMajorAxisKm,
    required this.eccentricity,
    required this.inclination,
    required this.ascendingNode,
    required this.argumentOfPeriapsis,
    required this.meanAnomaly,
    required this.periodDays,
    required this.magnitudeAtOpposition,
    required this.diameterKm,
    required this.color,
  });
}

/// Offline ephemeris for the Sun, Moon, and major planets based on JPL's
/// approximate Keplerian elements (Standish 1992) and Meeus lunar terms.
class PlanetaryEphemeris {
  // One-way light travel time per AU, expressed in Julian days.
  static const double _lightTimeDaysPerAu = 499.004783836 / 86400.0;

  /// Solves Kepler's equation for Eccentric Anomaly: M = E - e*sin(E).
  /// Uses Newton-Raphson iteration, converging to 1e-9 within 3-4 steps.
  static double _solveKepler(double meanAnomalyRad, double eccentricity) {
    double e = meanAnomalyRad;
    const maxIter = 20;
    const tolerance = 1e-9;

    for (int i = 0; i < maxIter; i++) {
      final delta = e - (eccentricity * math.sin(e)) - meanAnomalyRad;
      if (delta.abs() < tolerance) break;
      final derivative = 1.0 - (eccentricity * math.cos(e));
      e -= delta / derivative;
    }
    return e;
  }

  /// Computes heliocentric Cartesian coordinates (X, Y, Z in AU) from Keplerian elements.
  /// Includes NASA JPL Standish (1992) Table 2b periodic perturbation terms for outer planets.
  static ({double x, double y, double z}) _heliocentricCoordinates(
    _KeplerianElements elem, {
    PlanetType? type,
    double tCenturies = 0.0,
  }) {
    // Mean anomaly M = L - w + Standish Table 2b periodic perturbations
    double mDeg = elem.l - elem.w;
    if (type != null) {
      final t = tCenturies;
      switch (type) {
        case PlanetType.jupiter:
          final fRad = SphericalGeometry.toRadians(38.35125 * t);
          mDeg +=
              (-0.00012452 * t * t) +
              (0.06064060 * math.cos(fRad)) +
              (-0.35635438 * math.sin(fRad));
          break;
        case PlanetType.saturn:
          final fRad = SphericalGeometry.toRadians(38.35125 * t);
          mDeg +=
              (0.00025899 * t * t) +
              (-0.13434469 * math.cos(fRad)) +
              (0.87320147 * math.sin(fRad));
          break;
        case PlanetType.uranus:
          final fRad = SphericalGeometry.toRadians(7.67025 * t);
          mDeg +=
              (0.00058331 * t * t) +
              (-0.97731848 * math.cos(fRad)) +
              (0.17689245 * math.sin(fRad));
          break;
        case PlanetType.neptune:
          final fRad = SphericalGeometry.toRadians(7.67025 * t);
          mDeg +=
              (-0.00041348 * t * t) +
              (0.68346318 * math.cos(fRad)) +
              (-0.10162547 * math.sin(fRad));
          break;
        default:
          break;
      }
    }

    mDeg = SphericalGeometry.normalizeDegrees180(mDeg);
    final mRad = SphericalGeometry.toRadians(mDeg);

    // Eccentric anomaly E
    final eRad = _solveKepler(mRad, elem.e);

    // Coordinates in orbital plane
    final xPrime = elem.a * (math.cos(eRad) - elem.e);
    final yPrime = elem.a * math.sqrt(1.0 - elem.e * elem.e) * math.sin(eRad);

    // Argument of perihelion omega = w - node
    final omegaRad = SphericalGeometry.toRadians(elem.w - elem.node);
    final nodeRad = SphericalGeometry.toRadians(elem.node);
    final incRad = SphericalGeometry.toRadians(elem.i);

    final cosOmega = math.cos(omegaRad);
    final sinOmega = math.sin(omegaRad);
    final cosNode = math.cos(nodeRad);
    final sinNode = math.sin(nodeRad);
    final cosInc = math.cos(incRad);
    final sinInc = math.sin(incRad);

    // Rotation from orbital plane to heliocentric ecliptic
    final x =
        (cosOmega * cosNode - sinOmega * sinNode * cosInc) * xPrime +
        (-sinOmega * cosNode - cosOmega * sinNode * cosInc) * yPrime;
    final y =
        (cosOmega * sinNode + sinOmega * cosNode * cosInc) * xPrime +
        (-sinOmega * sinNode + cosOmega * cosNode * cosInc) * yPrime;
    final z = (sinOmega * sinInc) * xPrime + (cosOmega * sinInc) * yPrime;

    return (x: x, y: y, z: z);
  }

  /// Converts geocentric ecliptic coordinates (X, Y, Z in J2000 frame) to
  /// Equatorial (RA, Dec in degrees) precessed to the epoch of observation.
  static ({double ra, double dec}) _eclipticToEquatorial(
    double x,
    double y,
    double z,
    double tCenturies, {
    bool applyPrecession = true,
  }) {
    // Obliquity of the ecliptic at J2000 (Standish/IAU standard)
    const epsDeg = 23.4392911;
    final epsRad = SphericalGeometry.toRadians(epsDeg);
    final cosEps = math.cos(epsRad);
    final sinEps = math.sin(epsRad);

    // Equatorial Cartesian in J2000 frame:
    final xEq = x;
    final yEq = (y * cosEps) - (z * sinEps);
    final zEq = (y * sinEps) + (z * cosEps);

    final delta = math.sqrt(xEq * xEq + yEq * yEq + zEq * zEq);
    double decDeg = SphericalGeometry.toDegrees(
      math.asin(SphericalGeometry.clamp(zEq / delta, -1.0, 1.0)),
    );
    double raDeg = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(math.atan2(yEq, xEq)),
    );

    // Rigorous precession from J2000 to epoch of date (T).
    // Ensures coordinates align with precessed stars and date-referenced LST/GMST.
    if (applyPrecession && tCenturies.abs() > 0.0001) {
      final prec = CoordinateTransform.applyPrecessionJ2000(
        raDeg: raDeg,
        decDeg: decDeg,
        tCenturies: tCenturies,
      );
      raDeg = prec.rightAscension;
      decDeg = prec.declination;
    }

    return (ra: raDeg, dec: decDeg);
  }

  /// Evaluates NASA JPL Keplerian elements for a planet at century [t].
  static _KeplerianElements _getElements(PlanetType type, double t) {
    switch (type) {
      case PlanetType.mercury:
        return _KeplerianElements(
          a: 0.38709927 + (0.00000037 * t),
          e: 0.20563593 + (0.00001906 * t),
          i: 7.00497902 - (0.00594749 * t),
          l: 252.25032350 + (149472.67411175 * t),
          w: 77.45779628 + (0.16047689 * t),
          node: 48.33076593 - (0.12534081 * t),
        );
      case PlanetType.venus:
        return _KeplerianElements(
          a: 0.72333566 + (0.00000390 * t),
          e: 0.00677672 - (0.00004107 * t),
          i: 3.39467605 - (0.00078890 * t),
          l: 181.97909950 + (58517.81538729 * t),
          w: 131.60246718 + (0.00268329 * t),
          node: 76.67984255 - (0.27769418 * t),
        );
      case PlanetType.mars:
        return _KeplerianElements(
          a: 1.52371034 + (0.00001847 * t),
          e: 0.09339410 + (0.00007882 * t),
          i: 1.84969142 - (0.00813131 * t),
          l: -4.55343205 + (19140.30268499 * t),
          w: -23.94362959 + (0.44441088 * t),
          node: 49.55953891 - (0.29257343 * t),
        );
      case PlanetType.jupiter:
        return _KeplerianElements(
          a: 5.20288700 - (0.00011607 * t),
          e: 0.04838624 - (0.00013253 * t),
          i: 1.30439695 - (0.00183714 * t),
          l: 34.39644051 + (3034.74612775 * t),
          w: 14.72847983 + (0.21252668 * t),
          node: 100.47390909 + (0.20469106 * t),
        );
      case PlanetType.saturn:
        return _KeplerianElements(
          a: 9.53667594 - (0.00125060 * t),
          e: 0.05386179 - (0.00050991 * t),
          i: 2.48599187 + (0.00193609 * t),
          l: 49.95424423 + (1222.49362201 * t),
          w: 92.59887831 - (0.41897216 * t),
          node: 113.66242448 - (0.28867794 * t),
        );
      case PlanetType.uranus:
        return _KeplerianElements(
          a: 19.18916464 - (0.00196176 * t),
          e: 0.04725744 - (0.00004397 * t),
          i: 0.77263783 - (0.00242939 * t),
          l: 313.23810451 + (428.48202785 * t),
          w: 170.95427630 + (0.40805281 * t),
          node: 74.01692503 + (0.04240589 * t),
        );
      case PlanetType.neptune:
        return _KeplerianElements(
          a: 30.06992276 + (0.00026291 * t),
          e: 0.00860610 + (0.00005105 * t),
          i: 1.77004347 + (0.00035372 * t),
          l: -55.12002969 + (218.45945325 * t),
          w: 44.96476227 - (0.32241464 * t),
          node: 131.78422574 - (0.00508664 * t),
        );
      case PlanetType.pluto:
        return _KeplerianElements(
          a: 39.48168677 - (0.00076912 * t),
          e: 0.24880766 + (0.00006465 * t),
          i: 17.14175 - (0.003075 * t),
          l: 238.92881 + (145.20780515 * t),
          w: 224.06676 - (0.04062942 * t),
          node: 110.30347 - (0.010598 * t),
        );
      case PlanetType.earth:
        return _KeplerianElements(
          a: 1.00000261 + (0.00000562 * t),
          e: 0.01671123 - (0.00004392 * t),
          i: -0.00001531 - (0.01294668 * t),
          l: 100.46457166 + (35999.37244981 * t),
          w: 102.93768193 + (0.32327364 * t),
          node: 0.0,
        );
      default:
        throw ArgumentError('$type does not have a heliocentric orbit');
    }
  }

  /// Computes geocentric coordinates and physical attributes for the Sun.
  static Planet computeSun(DateTime utcDateTime) {
    return computeAllPlanets(
      utcDateTime,
    ).firstWhere((p) => p.type == PlanetType.sun);
  }

  /// Computes geocentric coordinates, phase, and illumination for the Moon.
  static Planet computeMoon(DateTime utcDateTime) {
    return computeAllPlanets(
      utcDateTime,
    ).firstWhere((p) => p.type == PlanetType.moon);
  }

  /// Computes all major planets, the Sun, and the Moon for a given UTC timestamp.
  static List<Planet> computeAllPlanets(DateTime utcDateTime) {
    final jd = AstronomicalTime.julianDate(utcDateTime);
    final t = AstronomicalTime.julianCenturiesJ2000(jd);

    // 1. Earth heliocentric coordinates
    final earthElements = _getElements(PlanetType.earth, t);
    final earthPos = _heliocentricCoordinates(earthElements, tCenturies: t);
    final rEarth = math.sqrt(
      earthPos.x * earthPos.x +
          earthPos.y * earthPos.y +
          earthPos.z * earthPos.z,
    );

    final List<Planet> result = [];

    // 2. The Sun (Geocentric vector = -EarthPos)
    final sunX = -earthPos.x;
    final sunY = -earthPos.y;
    final sunZ = -earthPos.z;
    final sunDistAu = rEarth;
    final sunEq = _eclipticToEquatorial(sunX, sunY, sunZ, t);
    final sunEclLon = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(math.atan2(sunY, sunX)),
    );

    result.add(
      Planet(
        id: 'SUN',
        name: 'Sun',
        type: PlanetType.sun,
        symbol: '☉',
        rightAscension: sunEq.ra,
        declination: sunEq.dec,
        apparentMagnitude: -26.74,
        eclipticLongitude: sunEclLon,
        eclipticLatitude: 0.0,
        distanceAu: sunDistAu,
        illuminatedFraction: 1.0,
        phaseName: 'Full Radiance',
        angularDiameterArcsec: (1919.26 / sunDistAu),
        baseColor: const Color(0xFFFFD700),
      ),
    );

    // 3. The Moon (Meeus analytical perturbation algorithm)
    final dDays = jd - 2451543.5;
    // Mean elements
    final lPrime = 218.316 + (13.176396 * dDays);
    final mPrime = 134.963 + (13.064993 * dDays);
    final f = 93.272 + (13.229350 * dDays);
    final d = 297.850 + (12.190749 * dDays);

    final mPrimeRad = SphericalGeometry.toRadians(mPrime);
    final fRad = SphericalGeometry.toRadians(f);
    final dRad = SphericalGeometry.toRadians(d);

    // Periodic perturbations
    final moonLonDeg = SphericalGeometry.normalizeDegrees360(
      lPrime +
          (6.289 * math.sin(mPrimeRad)) -
          (1.274 * math.sin(mPrimeRad - (2.0 * dRad))) +
          (0.658 * math.sin(2.0 * dRad)) -
          (0.214 * math.sin(2.0 * mPrimeRad)),
    );
    final moonLatDeg = SphericalGeometry.clamp(
      (5.128 * math.sin(fRad)) +
          (0.280 * math.sin(mPrimeRad + fRad)) +
          (0.277 * math.sin(mPrimeRad - fRad)),
      -90.0,
      90.0,
    );
    final moonDistKm =
        385001.0 -
        (20905.0 * math.cos(mPrimeRad)) -
        (3699.0 * math.cos((2.0 * dRad) - mPrimeRad));
    final moonDistAu = moonDistKm / 149597870.7;

    // Convert Moon ecliptic to Cartesian then Equatorial
    final moonLonRad = SphericalGeometry.toRadians(moonLonDeg);
    final moonLatRad = SphericalGeometry.toRadians(moonLatDeg);
    final cosMLat = math.cos(moonLatRad);
    final mX = cosMLat * math.cos(moonLonRad);
    final mY = cosMLat * math.sin(moonLonRad);
    final mZ = math.sin(moonLatRad);
    final moonEq = _eclipticToEquatorial(mX, mY, mZ, t);

    // Moon phase calculation
    final elongationDeg = SphericalGeometry.normalizeDegrees360(
      moonLonDeg - sunEclLon,
    );
    final illFraction = SphericalGeometry.clamp(
      (1.0 + math.cos(SphericalGeometry.toRadians(elongationDeg - 180.0))) /
          2.0,
      0.0,
      1.0,
    );
    final String phaseName = _moonPhaseName(elongationDeg);
    final moonMag =
        -12.74 +
        (2.5 * math.log((1.01 - illFraction).clamp(0.01, 1.0)) / math.ln10);

    result.add(
      Planet(
        id: 'MOON',
        name: 'Moon',
        type: PlanetType.moon,
        symbol: '☽',
        rightAscension: moonEq.ra,
        declination: moonEq.dec,
        apparentMagnitude: moonMag,
        eclipticLongitude: moonLonDeg,
        eclipticLatitude: moonLatDeg,
        distanceAu: moonDistAu,
        illuminatedFraction: illFraction,
        phaseName: phaseName,
        angularDiameterArcsec: (1873.7 * 384400.0 / moonDistKm),
        baseColor: const Color(0xFFECEFF1),
      ),
    );

    // 4. Major Planets: Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto
    const planets = [
      (
        type: PlanetType.mercury,
        id: 'MER',
        name: 'Mercury',
        symbol: '☿',
        color: Color(0xFFB0BEC5),
      ),
      (
        type: PlanetType.venus,
        id: 'VEN',
        name: 'Venus',
        symbol: '♀',
        color: Color(0xFFFFF9C4),
      ),
      (
        type: PlanetType.mars,
        id: 'MAR',
        name: 'Mars',
        symbol: '♂',
        color: Color(0xFFFF7043),
      ),
      (
        type: PlanetType.jupiter,
        id: 'JUP',
        name: 'Jupiter',
        symbol: '♃',
        color: Color(0xFFFFCC80),
      ),
      (
        type: PlanetType.saturn,
        id: 'SAT',
        name: 'Saturn',
        symbol: '♄',
        color: Color(0xFFFFE082),
      ),
      (
        type: PlanetType.uranus,
        id: 'URA',
        name: 'Uranus',
        symbol: '♅',
        color: Color(0xFF80DEEA),
      ),
      (
        type: PlanetType.neptune,
        id: 'NEP',
        name: 'Neptune',
        symbol: '♆',
        color: Color(0xFF81D4FA),
      ),
      (
        type: PlanetType.pluto,
        id: 'PLU',
        name: 'Pluto',
        symbol: '♇',
        color: Color(0xFFD7CCC8),
      ),
    ];

    for (final p in planets) {
      // The visible planet is where it was when its light left, not where the
      // orbit model places it at the instant the light reaches Earth. Iterate
      // the distance delay so inner planets receive the larger correction.
      var emissionCenturies = t;
      late ({double x, double y, double z}) pPos;
      late double gX;
      late double gY;
      late double gZ;
      late double distAu;
      for (var iteration = 0; iteration < 4; iteration++) {
        final elem = _getElements(p.type, emissionCenturies);
        pPos = _heliocentricCoordinates(
          elem,
          type: p.type,
          tCenturies: emissionCenturies,
        );

        // Geocentric vector joins Earth at observation time to the retarded
        // planet position.
        gX = pPos.x - earthPos.x;
        gY = pPos.y - earthPos.y;
        gZ = pPos.z - earthPos.z;
        distAu = math.sqrt(gX * gX + gY * gY + gZ * gZ);

        final correctedEmissionCenturies =
            t - (distAu * _lightTimeDaysPerAu / 36525.0);
        if ((correctedEmissionCenturies - emissionCenturies).abs() < 1e-12) {
          break;
        }
        emissionCenturies = correctedEmissionCenturies;
      }
      final rHelio = math.sqrt(
        pPos.x * pPos.x + pPos.y * pPos.y + pPos.z * pPos.z,
      );

      final eq = _eclipticToEquatorial(gX, gY, gZ, t);

      final eclLon = SphericalGeometry.normalizeDegrees360(
        SphericalGeometry.toDegrees(math.atan2(gY, gX)),
      );
      final eclLat = SphericalGeometry.toDegrees(
        math.asin(SphericalGeometry.clamp(gZ / distAu, -1.0, 1.0)),
      );

      // Phase angle: Sun - Planet - Earth
      // cos(phi) = (r^2 + Delta^2 - R^2) / (2 * r * Delta)
      final cosPhi = SphericalGeometry.clamp(
        (rHelio * rHelio + distAu * distAu - rEarth * rEarth) /
            (2.0 * rHelio * distAu),
        -1.0,
        1.0,
      );
      final phiDeg = SphericalGeometry.toDegrees(math.acos(cosPhi));
      final illFrac = (1.0 + cosPhi) / 2.0;

      // Apparent visual magnitude
      final vMag = _computePlanetMagnitude(p.type, rHelio, distAu, phiDeg);

      result.add(
        Planet(
          id: p.id,
          name: p.name,
          type: p.type,
          symbol: p.symbol,
          rightAscension: eq.ra,
          declination: eq.dec,
          apparentMagnitude: vMag,
          eclipticLongitude: eclLon,
          eclipticLatitude: eclLat,
          distanceAu: distAu,
          illuminatedFraction: illFrac,
          phaseName: '${(illFrac * 100).toStringAsFixed(0)}% Illuminated',
          angularDiameterArcsec: _angularDiameter(p.type, distAu),
          baseColor: p.color,
        ),
      );
    }

    return result;
  }

  /// Computes additional Solar System targets from JPL osculating elements.
  /// These reduced two-body solutions are useful for finding and do not replace
  /// a full Horizons integration for precision observing or occultation work.
  static List<Planet> computeAdditionalBodies(DateTime utcDateTime) {
    final jd = AstronomicalTime.julianDate(utcDateTime);
    final t = AstronomicalTime.julianCenturiesJ2000(jd);
    final earth = _heliocentricCoordinates(_getElements(PlanetType.earth, t));
    final jupiter = _heliocentricCoordinates(
      _getElements(PlanetType.jupiter, t),
      type: PlanetType.jupiter,
      tCenturies: t,
    );

    const osculatingEpoch = 2461200.5; // 2026-06-06, JPL SBDB solution epoch.
    const bodies = <_OsculatingBody>[
      _OsculatingBody(
        id: 'CER',
        name: 'Ceres',
        type: PlanetType.dwarfPlanet,
        symbol: 'C',
        a: 2.765552595,
        e: 0.079692295,
        i: 10.5880278,
        node: 80.2486268,
        argumentOfPerihelion: 73.2942145,
        meanAnomaly: 274.4193464,
        epochJd: osculatingEpoch,
        absoluteMagnitude: 3.34,
        slopeParameter: 0.12,
        diameterKm: 939.4,
        color: Color(0xFFBCAAA4),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description:
            'The largest object in the asteroid belt and a dwarf planet.',
      ),
      _OsculatingBody(
        id: 'VES',
        name: 'Vesta',
        type: PlanetType.asteroid,
        symbol: 'V',
        a: 2.361365965,
        e: 0.090203744,
        i: 7.1439255,
        node: 103.7012933,
        argumentOfPerihelion: 151.4686478,
        meanAnomaly: 81.1901561,
        epochJd: osculatingEpoch,
        absoluteMagnitude: 3.20,
        slopeParameter: 0.32,
        diameterKm: 525.4,
        color: Color(0xFFFFCC80),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description:
            'A differentiated protoplanet and the second-largest asteroid by mass.',
      ),
      _OsculatingBody(
        id: 'PAL',
        name: 'Pallas',
        type: PlanetType.asteroid,
        symbol: 'P',
        a: 2.769559011,
        e: 0.230700100,
        i: 34.9327932,
        node: 172.8866193,
        argumentOfPerihelion: 310.9699162,
        meanAnomaly: 254.2496522,
        epochJd: osculatingEpoch,
        absoluteMagnitude: 4.13,
        slopeParameter: 0.11,
        diameterKm: 512,
        color: Color(0xFFB0BEC5),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description: 'A large asteroid with an unusually inclined orbit.',
      ),
      _OsculatingBody(
        id: 'JUN',
        name: 'Juno',
        type: PlanetType.asteroid,
        symbol: 'J',
        a: 2.670989527,
        e: 0.255699984,
        i: 12.9865924,
        node: 169.8115953,
        argumentOfPerihelion: 247.8950743,
        meanAnomaly: 262.7322945,
        epochJd: osculatingEpoch,
        absoluteMagnitude: 5.33,
        slopeParameter: 0.32,
        diameterKm: 233,
        color: Color(0xFF90A4AE),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description: 'One of the largest main-belt asteroids.',
      ),
      _OsculatingBody(
        id: 'ERI',
        name: 'Eris',
        type: PlanetType.dwarfPlanet,
        symbol: 'E',
        a: 67.9339469,
        e: 0.438238535,
        i: 43.9258279,
        node: 36.0047704,
        argumentOfPerihelion: 150.7949236,
        meanAnomaly: 211.7744343,
        epochJd: osculatingEpoch,
        absoluteMagnitude: -1.19,
        diameterKm: 2326,
        color: Color(0xFFECEFF1),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description: 'A distant dwarf planet in the scattered disc.',
      ),
      _OsculatingBody(
        id: 'HAU',
        name: 'Haumea',
        type: PlanetType.dwarfPlanet,
        symbol: 'H',
        a: 43.0602902,
        e: 0.194443015,
        i: 28.2084739,
        node: 121.7860561,
        argumentOfPerihelion: 240.6905471,
        meanAnomaly: 223.2104119,
        epochJd: osculatingEpoch,
        absoluteMagnitude: 0.20,
        diameterKm: 1632,
        color: Color(0xFFB3E5FC),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description: 'A rapidly rotating dwarf planet beyond Neptune.',
      ),
      _OsculatingBody(
        id: 'MAK',
        name: 'Makemake',
        type: PlanetType.dwarfPlanet,
        symbol: 'M',
        a: 45.5709332,
        e: 0.158888995,
        i: 29.0278560,
        node: 79.2948338,
        argumentOfPerihelion: 297.0922733,
        meanAnomaly: 169.9379962,
        epochJd: osculatingEpoch,
        absoluteMagnitude: -0.30,
        diameterKm: 1430,
        color: Color(0xFFFFCCBC),
        source: 'JPL SBDB; osculating elements, epoch JD 2461200.5',
        description: 'A large dwarf planet in the Kuiper belt.',
      ),
      _OsculatingBody(
        id: 'HALLEY',
        name: "Halley's Comet",
        type: PlanetType.comet,
        symbol: '☄',
        a: 17.9286350,
        e: 0.967935996,
        i: 162.1905300,
        node: 59.0989472,
        argumentOfPerihelion: 112.2414315,
        meanAnomaly: 274.3823371,
        epochJd: 2439875.5,
        absoluteMagnitude: 4.0,
        slopeParameter: 4.0,
        diameterKm: 11,
        color: Color(0xFF80DEEA),
        isComet: true,
        source:
            'JPL SBDB; osculating elements, epoch JD 2439875.5; nongravitational terms omitted',
        description:
            'A periodic comet; this offline position uses a reduced Kepler orbit.',
      ),
    ];

    final result = <Planet>[];
    for (final body in bodies) {
      final meanMotion = 0.9856076686 / math.pow(body.a, 1.5).toDouble();
      final meanAnomaly = body.meanAnomaly + meanMotion * (jd - body.epochJd);
      final longitudeOfPerihelion = body.node + body.argumentOfPerihelion;
      final elements = _KeplerianElements(
        a: body.a,
        e: body.e,
        i: body.i,
        l: meanAnomaly + longitudeOfPerihelion,
        w: longitudeOfPerihelion,
        node: body.node,
      );
      final heliocentric = _heliocentricCoordinates(elements);
      result.add(
        _makeSmallBody(
          body: body,
          heliocentric: heliocentric,
          earth: earth,
          tCenturies: t,
        ),
      );
    }

    const satelliteEpoch = 2461041.5; // JPL Horizons elements at 2026-01-01.
    const satellites = <_GalileanOrbit>[
      _GalileanOrbit(
        id: 'IO',
        name: 'Io',
        symbol: 'Io',
        semiMajorAxisKm: 422029.043,
        eccentricity: 0.00398794,
        inclination: 2.2065244,
        ascendingNode: 338.4807022,
        argumentOfPeriapsis: -83.3993081,
        meanAnomaly: 97.5089286,
        periodDays: 1.769137786,
        magnitudeAtOpposition: 5.02,
        diameterKm: 3643.2,
        color: Color(0xFFFFD54F),
      ),
      _GalileanOrbit(
        id: 'EUROPA',
        name: 'Europa',
        symbol: 'Eu',
        semiMajorAxisKm: 671309.892,
        eccentricity: 0.00928618,
        inclination: 2.1504280,
        ascendingNode: 325.9353276,
        argumentOfPeriapsis: -249.6272944,
        meanAnomaly: 235.6424338,
        periodDays: 3.551,
        magnitudeAtOpposition: 5.29,
        diameterKm: 3121.6,
        color: Color(0xFFE1F5FE),
      ),
      _GalileanOrbit(
        id: 'GANYMEDE',
        name: 'Ganymede',
        symbol: 'Ga',
        semiMajorAxisKm: 1070853.599,
        eccentricity: 0.00218575,
        inclination: 2.3390454,
        ascendingNode: 339.2305455,
        argumentOfPeriapsis: -0.7055204,
        meanAnomaly: 23.3777232,
        periodDays: 7.155,
        magnitudeAtOpposition: 4.61,
        diameterKm: 5268.2,
        color: Color(0xFFCFD8DC),
      ),
      _GalileanOrbit(
        id: 'CALLISTO',
        name: 'Callisto',
        symbol: 'Ca',
        semiMajorAxisKm: 1882639.568,
        eccentricity: 0.00734675,
        inclination: 1.9516177,
        ascendingNode: 336.7028373,
        argumentOfPeriapsis: -303.4905971,
        meanAnomaly: 78.9285139,
        periodDays: 16.689,
        magnitudeAtOpposition: 5.65,
        diameterKm: 4820.6,
        color: Color(0xFFBCAAA4),
      ),
    ];

    for (final satellite in satellites) {
      final meanAnomaly =
          satellite.meanAnomaly +
          (360.0 / satellite.periodDays) * (jd - satelliteEpoch);
      final longitudeOfPeriapsis =
          satellite.ascendingNode + satellite.argumentOfPeriapsis;
      final relativeOrbit = _heliocentricCoordinates(
        _KeplerianElements(
          a: satellite.semiMajorAxisKm / 149597870.7,
          e: satellite.eccentricity,
          i: satellite.inclination,
          l: meanAnomaly + longitudeOfPeriapsis,
          w: longitudeOfPeriapsis,
          node: satellite.ascendingNode,
        ),
      );
      final heliocentric = (
        x: jupiter.x + relativeOrbit.x,
        y: jupiter.y + relativeOrbit.y,
        z: jupiter.z + relativeOrbit.z,
      );
      final geoX = heliocentric.x - earth.x;
      final geoY = heliocentric.y - earth.y;
      final geoZ = heliocentric.z - earth.z;
      final distance = math.sqrt(geoX * geoX + geoY * geoY + geoZ * geoZ);
      final eq = _eclipticToEquatorial(geoX, geoY, geoZ, t);
      final lon = SphericalGeometry.normalizeDegrees360(
        SphericalGeometry.toDegrees(math.atan2(geoY, geoX)),
      );
      final lat = SphericalGeometry.toDegrees(
        math.asin(SphericalGeometry.clamp(geoZ / distance, -1.0, 1.0)),
      );
      final distanceKm = distance * 149597870.7;
      result.add(
        Planet(
          id: satellite.id,
          name: satellite.name,
          type: PlanetType.galileanMoon,
          symbol: satellite.symbol,
          rightAscension: eq.ra,
          declination: eq.dec,
          apparentMagnitude:
              satellite.magnitudeAtOpposition +
              (5.0 * math.log(distance / 5.2) / math.ln10),
          eclipticLongitude: lon,
          eclipticLatitude: lat,
          distanceAu: distance,
          illuminatedFraction: 1.0,
          phaseName: 'Jupiter moon',
          angularDiameterArcsec: satellite.diameterKm / distanceKm * 206264.806,
          baseColor: satellite.color,
          ephemerisSource:
              'JPL Horizons osculating satellite elements at JD 2461041.5; Kepler propagation',
          description:
              'A Galilean moon of Jupiter. Apparent position is a reduced offline orbit.',
        ),
      );
    }
    return result;
  }

  static Planet _makeSmallBody({
    required _OsculatingBody body,
    required ({double x, double y, double z}) heliocentric,
    required ({double x, double y, double z}) earth,
    required double tCenturies,
  }) {
    final x = heliocentric.x - earth.x;
    final y = heliocentric.y - earth.y;
    final z = heliocentric.z - earth.z;
    final delta = math.sqrt(x * x + y * y + z * z);
    final r = math.sqrt(
      heliocentric.x * heliocentric.x +
          heliocentric.y * heliocentric.y +
          heliocentric.z * heliocentric.z,
    );
    final eq = _eclipticToEquatorial(x, y, z, tCenturies);
    final longitude = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(math.atan2(y, x)),
    );
    final latitude = SphericalGeometry.toDegrees(
      math.asin(SphericalGeometry.clamp(z / delta, -1.0, 1.0)),
    );
    final cosPhase = SphericalGeometry.clamp(
      (r * r + delta * delta - 1.0) / (2.0 * r * delta),
      -1.0,
      1.0,
    );
    final phase = math.acos(cosPhase);
    final distanceModulus = 5.0 * math.log(r * delta) / math.ln10;
    double magnitude;
    if (body.isComet) {
      magnitude =
          body.absoluteMagnitude +
          (5.0 * math.log(delta) / math.ln10) +
          (2.5 * body.slopeParameter * math.log(r) / math.ln10);
    } else {
      final tangent = math.tan(phase / 2.0);
      final phi1 = math.exp(-3.33 * math.pow(tangent, 0.63).toDouble());
      final phi2 = math.exp(-1.87 * math.pow(tangent, 1.22).toDouble());
      final phaseFactor =
          ((1.0 - body.slopeParameter) * phi1) + (body.slopeParameter * phi2);
      magnitude =
          body.absoluteMagnitude +
          distanceModulus -
          (2.5 * math.log(math.max(phaseFactor, 1e-12)) / math.ln10);
    }
    final distanceKm = delta * 149597870.7;
    return Planet(
      id: body.id,
      name: body.name,
      type: body.type,
      symbol: body.symbol,
      rightAscension: eq.ra,
      declination: eq.dec,
      apparentMagnitude: magnitude,
      eclipticLongitude: longitude,
      eclipticLatitude: latitude,
      distanceAu: delta,
      illuminatedFraction: 1.0,
      phaseName: body.isComet ? 'Comet; approximate brightness' : 'Minor body',
      angularDiameterArcsec: body.diameterKm / distanceKm * 206264.806,
      baseColor: body.color,
      ephemerisSource: body.source,
      description: body.description,
    );
  }

  static String _moonPhaseName(double elongation) {
    if (elongation < 22.5 || elongation >= 337.5) return 'New Moon';
    if (elongation < 67.5) return 'Waxing Crescent';
    if (elongation < 112.5) return 'First Quarter';
    if (elongation < 157.5) return 'Waxing Gibbous';
    if (elongation < 202.5) return 'Full Moon';
    if (elongation < 247.5) return 'Waning Gibbous';
    if (elongation < 292.5) return 'Third Quarter';
    return 'Waning Crescent';
  }

  static double _computePlanetMagnitude(
    PlanetType type,
    double r,
    double delta,
    double phi,
  ) {
    final fiveLogRDelta = 5.0 * math.log(r * delta) / math.ln10;

    switch (type) {
      case PlanetType.mercury:
        final pClamped = phi.clamp(0.0, 160.0);
        final v =
            -0.60 +
            fiveLogRDelta +
            (0.0498 * pClamped) -
            (0.000488 * pClamped * pClamped) +
            (0.00000302 * pClamped * pClamped * pClamped);
        return v.clamp(-2.5, 6.0);
      case PlanetType.venus:
        return -4.40 + fiveLogRDelta + (0.0009 * phi) + (0.000239 * phi * phi);
      case PlanetType.mars:
        return -1.52 + fiveLogRDelta + (0.016 * phi);
      case PlanetType.jupiter:
        return -9.40 + fiveLogRDelta + (0.005 * phi);
      case PlanetType.saturn:
        return -8.88 + fiveLogRDelta + (0.044 * phi);
      case PlanetType.uranus:
        return -7.19 + fiveLogRDelta;
      case PlanetType.neptune:
        return -6.87 + fiveLogRDelta;
      case PlanetType.pluto:
        return -1.0 + fiveLogRDelta + (0.041 * phi.clamp(0.0, 30.0));
      default:
        return 0.0;
    }
  }

  static double _angularDiameter(PlanetType type, double distAu) {
    // Equatorial diameters at 1 AU in arcseconds
    switch (type) {
      case PlanetType.mercury:
        return 6.74 / distAu;
      case PlanetType.venus:
        return 16.82 / distAu;
      case PlanetType.mars:
        return 9.36 / distAu;
      case PlanetType.jupiter:
        return 196.9 / distAu;
      case PlanetType.saturn:
        return 165.6 / distAu;
      case PlanetType.uranus:
        return 70.0 / distAu;
      case PlanetType.neptune:
        return 67.0 / distAu;
      case PlanetType.pluto:
        return 0.11 / distAu;
      default:
        return 10.0;
    }
  }
}
