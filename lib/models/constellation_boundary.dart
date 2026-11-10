/// A point on an official constellation boundary in J2000 equatorial degrees.
class BoundaryCoordinate {
  final double rightAscension;
  final double declination;

  const BoundaryCoordinate({
    required this.rightAscension,
    required this.declination,
  });

  factory BoundaryCoordinate.fromJson(List<dynamic> json) => BoundaryCoordinate(
    rightAscension: (json[0] as num).toDouble(),
    declination: (json[1] as num).toDouble(),
  );
}

/// One shared Delporte boundary between two IAU constellations.
class ConstellationBoundary {
  final List<String> constellations;
  final List<BoundaryCoordinate> points;

  const ConstellationBoundary({
    required this.constellations,
    required this.points,
  });

  factory ConstellationBoundary.fromJson(Map<String, dynamic> json) =>
      ConstellationBoundary(
        constellations: (json['constellations'] as List<dynamic>)
            .cast<String>(),
        points: (json['points'] as List<dynamic>)
            .map((point) => BoundaryCoordinate.fromJson(point as List<dynamic>))
            .toList(growable: false),
      );
}
