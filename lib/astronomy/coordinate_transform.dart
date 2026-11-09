import 'dart:math' as math;
import '../models/sky_position.dart';
import 'spherical_geometry.dart';

/// Rigorous transformations between Equatorial (RA, Dec) and Horizontal (Az, Alt) coordinate frames,
/// plus astronomical corrections (precession, proper motion, atmospheric refraction).
class CoordinateTransform {
  /// Converts Equatorial coordinates ([raDeg], [decDeg]) into Horizontal coordinates ([SkyPosition])
  /// for an observer at [latitudeDeg] and local sidereal time [lstDeg].
  ///
  /// Mathematical Formulation:
  /// Hour angle: H = LST - RA
  /// Altitude: sin(a) = sin(phi)*sin(dec) + cos(phi)*cos(dec)*cos(H)
  /// Azimuth: atan2(-sin(H)*cos(dec), sin(dec)*cos(phi) - cos(dec)*sin(phi)*cos(H))
  ///
  /// North-positive latitude, East-positive longitude.
  /// Azimuth is measured clockwise from True North (0° = North, 90° = East, 180° = South, 270° = West).
  static SkyPosition equatorialToHorizontal({
    required double raDeg,
    required double decDeg,
    required double latitudeDeg,
    required double lstDeg,
    bool applyRefraction = false,
  }) {
    final double hDeg = SphericalGeometry.normalizeDegrees360(lstDeg - raDeg);
    final double hRad = SphericalGeometry.toRadians(hDeg);
    final double decRad = SphericalGeometry.toRadians(decDeg);
    final double latRad = SphericalGeometry.toRadians(latitudeDeg);

    final double sinLat = math.sin(latRad);
    final double cosLat = math.cos(latRad);
    final double sinDec = math.sin(decRad);
    final double cosDec = math.cos(decRad);
    final double sinH = math.sin(hRad);
    final double cosH = math.cos(hRad);

    // Altitude: sin(a) = sin(phi)*sin(dec) + cos(phi)*cos(dec)*cos(H)
    final double sinAlt = SphericalGeometry.clamp(
      (sinLat * sinDec) + (cosLat * cosDec * cosH),
      -1.0,
      1.0,
    );
    double altitudeDeg = SphericalGeometry.toDegrees(math.asin(sinAlt));

    // Azimuth calculation
    // azimuth = atan2(-sin(H)*cos(dec), sin(dec)*cos(lat) - cos(dec)*sin(lat)*cos(H))
    final double y = -sinH * cosDec;
    final double x = (sinDec * cosLat) - (cosDec * sinLat * cosH);

    double azimuthDeg;
    // Explicit handling of the zenith / nadir singularity
    if (altitudeDeg >= 89.99999 || altitudeDeg <= -89.99999) {
      azimuthDeg = 0.0;
    } else {
      azimuthDeg = SphericalGeometry.normalizeDegrees360(
        SphericalGeometry.toDegrees(math.atan2(y, x)),
      );
    }

    if (applyRefraction) {
      altitudeDeg = addAtmosphericRefraction(altitudeDeg);
    }

    return SkyPosition(
      azimuth: azimuthDeg,
      altitude: altitudeDeg,
      hourAngle: hDeg,
    );
  }

  /// Converts Horizontal coordinates ([azimuthDeg], [altitudeDeg]) back into Equatorial coordinates
  /// (Right Ascension, Declination) for an observer at [latitudeDeg] and local sidereal time [lstDeg].
  static ({double rightAscension, double declination}) horizontalToEquatorial({
    required double azimuthDeg,
    required double altitudeDeg,
    required double latitudeDeg,
    required double lstDeg,
  }) {
    final double azRad = SphericalGeometry.toRadians(azimuthDeg);
    final double altRad = SphericalGeometry.toRadians(altitudeDeg);
    final double latRad = SphericalGeometry.toRadians(latitudeDeg);

    final double sinLat = math.sin(latRad);
    final double cosLat = math.cos(latRad);
    final double sinAlt = math.sin(altRad);
    final double cosAlt = math.cos(altRad);
    final double sinAz = math.sin(azRad);
    final double cosAz = math.cos(azRad);

    // sin(dec) = sin(lat)*sin(alt) + cos(lat)*cos(alt)*cos(az)
    final double sinDec = SphericalGeometry.clamp(
      (sinLat * sinAlt) + (cosLat * cosAlt * cosAz),
      -1.0,
      1.0,
    );
    final double decDeg = SphericalGeometry.toDegrees(math.asin(sinDec));

    // Hour angle H
    final double y = -sinAz * cosAlt;
    final double x = (sinAlt * cosLat) - (cosAlt * sinLat * cosAz);

    final double hDeg = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(math.atan2(y, x)),
    );

    // RA = LST - H
    final double raDeg = SphericalGeometry.normalizeDegrees360(lstDeg - hDeg);

    return (rightAscension: raDeg, declination: decDeg);
  }

  /// Bennett's (1982) formula for atmospheric refraction.
  /// Adds refraction angle to geometric altitude to yield apparent altitude.
  /// Only applies when altitude >= -1.0° to prevent divergence.
  static double addAtmosphericRefraction(double geometricAltDeg) {
    if (geometricAltDeg < -1.0) {
      return geometricAltDeg;
    }
    // R in arcminutes = 1.0 / tan(h + 7.31 / (h + 4.4))
    final double h = geometricAltDeg;
    final double arg = h + (7.31 / (h + 4.4));
    final double argRad = SphericalGeometry.toRadians(arg);
    final double tanArg = math.tan(argRad);
    if (tanArg.abs() < 1e-6) return geometricAltDeg;

    final double rArcminutes = 1.0 / tanArg;
    final double rDegrees = rArcminutes / 60.0;
    return geometricAltDeg + rDegrees;
  }

  /// Applies stellar proper motion from J2000.0 to observation epoch.
  /// [pmRaMasYr] is $\mu_\alpha \cos\delta$ in milliarcseconds/year.
  /// [pmDecMasYr] is $\mu_\delta$ in milliarcseconds/year.
  static ({double rightAscension, double declination}) applyProperMotion({
    required double raDeg,
    required double decDeg,
    required double pmRaMasYr,
    required double pmDecMasYr,
    required double yearsSinceJ2000,
  }) {
    final decRad = SphericalGeometry.toRadians(decDeg);
    final cosDec = math.cos(decRad);

    // pmRaMasYr is already mu_alpha * cos(delta) in mas/yr
    final dRaDeg =
        (pmRaMasYr * yearsSinceJ2000) /
        (3600000.0 * (cosDec.abs() > 1e-4 ? cosDec : 1.0));
    final dDecDeg = (pmDecMasYr * yearsSinceJ2000) / 3600000.0;

    final newRa = SphericalGeometry.normalizeDegrees360(raDeg + dRaDeg);
    final newDec = SphericalGeometry.clamp(decDeg + dDecDeg, -90.0, 90.0);

    return (rightAscension: newRa, declination: newDec);
  }

  /// Applies general precession from J2000.0 to the target Julian century [tCenturies]
  /// using the IAU 1976 precession matrix formulation (Lieske et al. 1977).
  static ({double rightAscension, double declination}) applyPrecessionJ2000({
    required double raDeg,
    required double decDeg,
    required double tCenturies,
  }) {
    if (tCenturies.abs() < 1e-7) {
      return (rightAscension: raDeg, declination: decDeg);
    }

    final t = tCenturies;
    final t2 = t * t;
    final t3 = t2 * t;

    // Precession angles in arcseconds
    final zetaArcsec = 2306.2181 * t + 0.30188 * t2 + 0.017998 * t3;
    final zArcsec = 2306.2181 * t + 1.09468 * t2 + 0.018203 * t3;
    final thetaArcsec = 2004.3109 * t - 0.42665 * t2 - 0.041833 * t3;

    final zetaRad = SphericalGeometry.toRadians(zetaArcsec / 3600.0);
    final zRad = SphericalGeometry.toRadians(zArcsec / 3600.0);
    final thetaRad = SphericalGeometry.toRadians(thetaArcsec / 3600.0);

    // Cartesian vector in J2000.0 equatorial coordinates
    final raRad = SphericalGeometry.toRadians(raDeg);
    final decRad = SphericalGeometry.toRadians(decDeg);
    final cosDec = math.cos(decRad);

    final x0 = cosDec * math.cos(raRad);
    final y0 = cosDec * math.sin(raRad);
    final z0 = math.sin(decRad);

    // Apply rotation matrix: Rz(-z) * Ry(theta) * Rz(-zeta)
    // 1) Rz(-zeta)
    final cosZeta = math.cos(zetaRad);
    final sinZeta = math.sin(zetaRad);
    final x1 = cosZeta * x0 - sinZeta * y0;
    final y1 = sinZeta * x0 + cosZeta * y0;
    final z1 = z0;

    // 2) Ry(theta)
    final cosTheta = math.cos(thetaRad);
    final sinTheta = math.sin(thetaRad);
    final x2 = cosTheta * x1 - sinTheta * z1;
    final y2 = y1;
    final z2 = sinTheta * x1 + cosTheta * z1;

    // 3) Rz(-z)
    final cosZ = math.cos(zRad);
    final sinZ = math.sin(zRad);
    final x3 = cosZ * x2 - sinZ * y2;
    final y3 = sinZ * x2 + cosZ * y2;
    final z3 = z2;

    // Convert back to spherical coordinates
    final newDec = SphericalGeometry.toDegrees(
      math.asin(SphericalGeometry.clamp(z3, -1.0, 1.0)),
    );
    final newRa = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(math.atan2(y3, x3)),
    );

    return (rightAscension: newRa, declination: newDec);
  }

  /// Converts Galactic longitude and latitude to J2000 equatorial coordinates.
  /// The IAU 1958 Galactic system is realized by the ICRS/J2000 rotation matrix.
  static ({double rightAscension, double declination}) galacticToEquatorial({
    required double longitudeDeg,
    required double latitudeDeg,
  }) {
    const matrix = [
      [-0.0548755604, 0.4941094279, -0.8676661490],
      [-0.8734370902, -0.4448296300, -0.1980763734],
      [-0.4838350155, 0.7469822445, 0.4559837762],
    ];
    final longitude = SphericalGeometry.toRadians(longitudeDeg);
    final latitude = SphericalGeometry.toRadians(latitudeDeg);
    final galX = math.cos(latitude) * math.cos(longitude);
    final galY = math.cos(latitude) * math.sin(longitude);
    final galZ = math.sin(latitude);

    // Transpose maps the galactic vector back into the equatorial frame.
    final x =
        (matrix[0][0] * galX) + (matrix[0][1] * galY) + (matrix[0][2] * galZ);
    final y =
        (matrix[1][0] * galX) + (matrix[1][1] * galY) + (matrix[1][2] * galZ);
    final z =
        (matrix[2][0] * galX) + (matrix[2][1] * galY) + (matrix[2][2] * galZ);
    return (
      rightAscension: SphericalGeometry.normalizeDegrees360(
        SphericalGeometry.toDegrees(math.atan2(y, x)),
      ),
      declination: SphericalGeometry.toDegrees(
        math.asin(SphericalGeometry.clamp(z, -1.0, 1.0)),
      ),
    );
  }
}
