/// Base class for any celestial body with equatorial coordinates.
abstract class CelestialObject {
  final String id;
  final String name;
  final double rightAscension; // in degrees [0, 360)
  final double declination; // in degrees [-90, +90]
  final double apparentMagnitude;

  const CelestialObject({
    required this.id,
    required this.name,
    required this.rightAscension,
    required this.declination,
    required this.apparentMagnitude,
  });

  /// Right ascension in hours [0, 24).
  double get rightAscensionHours => rightAscension / 15.0;
}
