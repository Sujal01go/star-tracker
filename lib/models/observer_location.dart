/// Represents the geographic coordinates of the terrestrial observer.
class ObserverLocation {
  /// Latitude in degrees [-90.0, +90.0], North-positive, South-negative.
  final double latitude;

  /// Longitude in degrees [-180.0, +180.0], East-positive, West-negative.
  final double longitude;

  /// Elevation above sea level in meters.
  final double altitudeMeters;

  /// Human-readable label (e.g. "New Delhi, India", "Greenwich", "GPS Location").
  final String name;

  const ObserverLocation({
    required this.latitude,
    required this.longitude,
    this.altitudeMeters = 0.0,
    this.name = 'Current Location',
  });

  /// Factory preset for Royal Observatory, Greenwich (Prime Meridian).
  static const greenwich = ObserverLocation(
    latitude: 51.4769,
    longitude: 0.0,
    altitudeMeters: 46.0,
    name: 'Greenwich, UK',
  );

  /// Preset for Tokyo, Japan.
  static const tokyo = ObserverLocation(
    latitude: 35.6762,
    longitude: 139.6503,
    altitudeMeters: 40.0,
    name: 'Tokyo, Japan',
  );

  /// Preset for New York City, USA.
  static const newYork = ObserverLocation(
    latitude: 40.7128,
    longitude: -74.0060,
    altitudeMeters: 10.0,
    name: 'New York, USA',
  );

  /// Preset for Sydney, Australia (Southern Hemisphere representation).
  static const sydney = ObserverLocation(
    latitude: -33.8688,
    longitude: 151.2093,
    altitudeMeters: 58.0,
    name: 'Sydney, Australia',
  );

  /// Preset for New Delhi, India.
  static const newDelhi = ObserverLocation(
    latitude: 28.6139,
    longitude: 77.2090,
    altitudeMeters: 216.0,
    name: 'New Delhi, India',
  );

  /// Preset for Mauna Kea Observatories, Hawaii.
  static const maunaKea = ObserverLocation(
    latitude: 19.8207,
    longitude: -155.4681,
    altitudeMeters: 4205.0,
    name: 'Mauna Kea, Hawaii',
  );

  static const List<ObserverLocation> presets = [
    greenwich,
    newDelhi,
    tokyo,
    newYork,
    sydney,
    maunaKea,
  ];

  ObserverLocation copyWith({
    double? latitude,
    double? longitude,
    double? altitudeMeters,
    String? name,
  }) {
    return ObserverLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      name: name ?? this.name,
    );
  }

  factory ObserverLocation.fromJson(Map<String, dynamic> json) {
    return ObserverLocation(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      altitudeMeters: (json['alt'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String? ?? 'Custom Location',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lon': longitude,
      'alt': altitudeMeters,
      'name': name,
    };
  }

  @override
  String toString() =>
      '$name (${latitude >= 0 ? '${latitude.toStringAsFixed(2)}°N' : '${(-latitude).toStringAsFixed(2)}°S'}, '
      '${longitude >= 0 ? '${longitude.toStringAsFixed(2)}°E' : '${(-longitude).toStringAsFixed(2)}°W'})';
}
