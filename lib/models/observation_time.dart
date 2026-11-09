/// Manages the astronomical observation time.
/// Uses UTC internally for all astronomical calculations, while supporting
/// local time display and live/simulated time modes.
class ObservationTime {
  /// The effective observation date and time in UTC.
  final DateTime utcDateTime;

  /// Whether the app is tracking real-time clock automatically.
  final bool isRealTime;

  /// Time simulation speed multiplier (1.0 = real-time, 60.0 = 1 minute per second, etc.).
  final double speedMultiplier;

  ObservationTime({
    DateTime? utcDateTime,
    this.isRealTime = true,
    this.speedMultiplier = 1.0,
  }) : utcDateTime = (utcDateTime ?? DateTime.now()).toUtc();

  /// Create an observation time set to the current system clock.
  factory ObservationTime.now() {
    return ObservationTime(
      utcDateTime: DateTime.now().toUtc(),
      isRealTime: true,
    );
  }

  /// Create a specific manual observation time.
  factory ObservationTime.manual(DateTime dateTime) {
    return ObservationTime(utcDateTime: dateTime.toUtc(), isRealTime: false);
  }

  /// Get local date time for UI presentation.
  DateTime get localDateTime => utcDateTime.toLocal();

  ObservationTime copyWith({
    DateTime? utcDateTime,
    bool? isRealTime,
    double? speedMultiplier,
  }) {
    return ObservationTime(
      utcDateTime: utcDateTime ?? this.utcDateTime,
      isRealTime: isRealTime ?? this.isRealTime,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
    );
  }
}
