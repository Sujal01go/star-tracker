import 'astronomical_time.dart';
import 'spherical_geometry.dart';

/// Calculations for Greenwich Mean Sidereal Time (GMST) and Local Sidereal Time (LST).
class SiderealTime {
  /// Computes the Greenwich Mean Sidereal Time (GMST) in degrees [0, 360)
  /// for a given Julian Date [jd].
  ///
  /// Uses the IAU standard formula:
  /// T = (JD - 2451545.0) / 36525
  /// GMST = 280.46061837
  ///        + 360.98564736629 * (JD - 2451545.0)
  ///        + 0.000387933 * T^2
  ///        - T^3 / 38710000
  static double greenwichMeanSiderealTime(double jd) {
    final double d = jd - AstronomicalTime.j2000Epoch;
    final double t = d / AstronomicalTime.daysPerJulianCentury;

    final double gmstDeg =
        280.46061837 +
        (360.98564736629 * d) +
        (0.000387933 * t * t) -
        ((t * t * t) / 38710000.0);

    return SphericalGeometry.normalizeDegrees360(gmstDeg);
  }

  /// Computes Greenwich Mean Sidereal Time (GMST) in hours [0, 24).
  static double greenwichMeanSiderealTimeHours(double jd) {
    return greenwichMeanSiderealTime(jd) / 15.0;
  }

  /// Computes Local Sidereal Time (LST) in degrees [0, 360) for a given
  /// GMST in degrees and observer longitude in degrees (East-positive).
  ///
  /// LST = GMST + observerLongitude
  static double localSiderealTime(double gmstDeg, double longitudeEastDeg) {
    final double lstDeg = gmstDeg + longitudeEastDeg;
    return SphericalGeometry.normalizeDegrees360(lstDeg);
  }

  /// Convenience method: Computes Local Sidereal Time (LST) in degrees [0, 360)
  /// directly from a UTC [DateTime] and observer longitude (East-positive).
  static double localSiderealTimeFromDateTime(
    DateTime utcDateTime,
    double longitudeEastDeg,
  ) {
    final jd = AstronomicalTime.julianDate(utcDateTime);
    final gmst = greenwichMeanSiderealTime(jd);
    return localSiderealTime(gmst, longitudeEastDeg);
  }

  /// Computes Local Hour Angle (H) in degrees for a celestial object with
  /// Right Ascension [raDeg] (in degrees) given Local Sidereal Time [lstDeg]:
  ///
  /// H = LST - RA
  /// Normalized to [0, 360) or [-180, +180].
  static double hourAngleDegrees(double lstDeg, double raDeg) {
    return SphericalGeometry.normalizeDegrees360(lstDeg - raDeg);
  }

  /// Computes Local Hour Angle (H) normalized to [-180, +180] degrees.
  /// Negative values indicate the object is East of the meridian (rising),
  /// Positive values indicate the object is West of the meridian (setting).
  static double hourAngleSignedDegrees(double lstDeg, double raDeg) {
    return SphericalGeometry.normalizeDegrees180(lstDeg - raDeg);
  }
}
