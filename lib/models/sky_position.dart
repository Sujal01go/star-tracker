/// Represents the computed horizontal coordinates of a celestial object
/// for an observer at a specific location and observation time.
class SkyPosition {
  /// Azimuth in degrees [0, 360), measured clockwise from True North:
  /// 0° = North, 90° = East, 180° = South, 270° = West.
  final double azimuth;

  /// Altitude in degrees [-90, +90]:
  /// 0° = Astronomical Horizon, +90° = Zenith, -90° = Nadir.
  final double altitude;

  /// Local hour angle in degrees [-180, +180] or [0, 360).
  final double? hourAngle;

  /// Zenith angle in degrees [0, 180], where 90° - altitude.
  double get zenithAngle => 90.0 - altitude;

  /// True if the object is above the theoretical horizon (altitude >= 0°).
  bool get isVisible => altitude >= 0.0;

  /// True if the object is within 0.1 degrees of the zenith where azimuth
  /// is geometrically degenerate.
  bool get isZenith => altitude >= 89.9;

  const SkyPosition({
    required this.azimuth,
    required this.altitude,
    this.hourAngle,
  });

  @override
  String toString() =>
      'SkyPosition(alt: ${altitude.toStringAsFixed(2)}°, az: ${azimuth.toStringAsFixed(2)}°)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkyPosition &&
          runtimeType == other.runtimeType &&
          azimuth == other.azimuth &&
          altitude == other.altitude;

  @override
  int get hashCode => azimuth.hashCode ^ altitude.hashCode;
}
