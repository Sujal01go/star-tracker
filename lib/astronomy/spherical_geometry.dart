import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Spherical geometry utilities for astronomical calculations.
class SphericalGeometry {
  static const double deg2rad = math.pi / 180.0;
  static const double rad2deg = 180.0 / math.pi;

  /// Converts degrees to radians.
  static double toRadians(double degrees) => degrees * deg2rad;

  /// Converts radians to degrees.
  static double toDegrees(double radians) => radians * rad2deg;

  /// Normalizes an angle in degrees into the range [0.0, 360.0).
  static double normalizeDegrees360(double degrees) {
    double result = degrees % 360.0;
    if (result < 0.0) {
      result += 360.0;
    }
    if (result >= 360.0 || (result - 360.0).abs() < 1e-12) {
      result = 0.0;
    }
    // Prevent -0.0
    return result == 0.0 ? 0.0 : result;
  }

  /// Normalizes an angle in degrees into the range [-180.0, +180.0].
  static double normalizeDegrees180(double degrees) {
    double result = normalizeDegrees360(degrees);
    if (result > 180.0) {
      result -= 360.0;
    }
    return result;
  }

  /// Clamps a floating-point value to [min, max] to prevent NaN from rounding errors in trigonometric inverses.
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Converts horizontal coordinates (azimuth, altitude) in degrees
  /// into a 3D unit vector in a topocentric frame:
  /// X = East, Y = North, Z = Up (Zenith).
  ///
  /// Azimuth is measured clockwise from North:
  /// North (0°): (0, 1, 0)
  /// East (90°): (1, 0, 0)
  /// South (180°): (0, -1, 0)
  /// West (270°): (-1, 0, 0)
  /// Zenith (+90°): (0, 0, 1)
  static Vector3 horizontalToUnitVector(double azimuthDeg, double altitudeDeg) {
    final azRad = toRadians(azimuthDeg);
    final altRad = toRadians(altitudeDeg);
    final cosAlt = math.cos(altRad);

    final x = cosAlt * math.sin(azRad); // East
    final y = cosAlt * math.cos(azRad); // North
    final z = math.sin(altRad); // Zenith

    return Vector3(x, y, z);
  }

  /// Converts a topocentric 3D unit vector (X=East, Y=North, Z=Zenith)
  /// back into horizontal coordinates (azimuth, altitude) in degrees.
  static ({double azimuth, double altitude}) unitVectorToHorizontal(Vector3 v) {
    final norm = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if (norm == 0.0) {
      return (azimuth: 0.0, altitude: 0.0);
    }
    final x = v.x / norm;
    final y = v.y / norm;
    final z = clamp(v.z / norm, -1.0, 1.0);

    final altitude = toDegrees(math.asin(z));
    double azimuth;
    if (altitude >= 89.99999) {
      // Zenith singularity: azimuth is undefined; assign 0.0
      azimuth = 0.0;
    } else if (altitude <= -89.99999) {
      // Nadir singularity
      azimuth = 0.0;
    } else {
      azimuth = normalizeDegrees360(toDegrees(math.atan2(x, y)));
    }

    return (azimuth: azimuth, altitude: altitude);
  }

  /// Computes the great-circle angular separation in degrees between two
  /// points on a sphere (e.g. RA/Dec or Az/Alt) using the numerically stable Vincenty formula.
  static double angularDistance(
    double lon1Deg,
    double lat1Deg,
    double lon2Deg,
    double lat2Deg,
  ) {
    final l1 = toRadians(lon1Deg);
    final b1 = toRadians(lat1Deg);
    final l2 = toRadians(lon2Deg);
    final b2 = toRadians(lat2Deg);

    final dLon = l2 - l1;
    final cosB2 = math.cos(b2);
    final sinB2 = math.sin(b2);
    final cosB1 = math.cos(b1);
    final sinB1 = math.sin(b1);
    final cosDLon = math.cos(dLon);
    final sinDLon = math.sin(dLon);

    final numerator = math.sqrt(
      math.pow(cosB2 * sinDLon, 2) +
          math.pow(cosB1 * sinB2 - sinB1 * cosB2 * cosDLon, 2),
    );
    final denominator = sinB1 * sinB2 + cosB1 * cosB2 * cosDLon;

    return toDegrees(math.atan2(numerator, denominator));
  }
}
