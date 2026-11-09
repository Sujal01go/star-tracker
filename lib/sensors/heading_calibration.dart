/// Sensor calibration state, accuracy level, and user heading offsets.
enum SensorAccuracy { unreliable, low, medium, high }

class HeadingCalibration {
  /// User-configurable azimuth calibration offset in degrees (-180° to +180°).
  final double manualHeadingOffset;

  /// Magnetic declination angle for geographic location in degrees.
  final double magneticDeclination;

  /// Sensor calibration accuracy reported by the hardware.
  final SensorAccuracy accuracy;

  /// Number of calibration samples collected.
  final int samplesCount;

  const HeadingCalibration({
    this.manualHeadingOffset = 0.0,
    this.magneticDeclination = 0.0,
    this.accuracy = SensorAccuracy.unreliable,
    this.samplesCount = 0,
  });

  /// Total azimuth correction to apply to raw magnetic heading.
  double get totalOffsetDegrees => manualHeadingOffset + magneticDeclination;

  HeadingCalibration copyWith({
    double? manualHeadingOffset,
    double? magneticDeclination,
    SensorAccuracy? accuracy,
    int? samplesCount,
  }) {
    return HeadingCalibration(
      manualHeadingOffset: manualHeadingOffset ?? this.manualHeadingOffset,
      magneticDeclination: magneticDeclination ?? this.magneticDeclination,
      accuracy: accuracy ?? this.accuracy,
      samplesCount: samplesCount ?? this.samplesCount,
    );
  }
}
