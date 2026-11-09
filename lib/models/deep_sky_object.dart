/// A fixed deep-sky target in the J2000 equatorial reference frame.
class DeepSkyObject {
  final String id;
  final String name;
  final List<String> catalogueIdentifiers;
  final List<String> aliases;
  final String objectType;
  final double rightAscension;
  final double declination;
  final double? apparentMagnitude;
  final double? distanceLightYears;
  final double? angularSizeMajorArcminutes;
  final double? angularSizeMinorArcminutes;
  final String? constellation;
  final String description;
  final String visibilityClass;
  final String source;
  final double coordinateEpoch;

  const DeepSkyObject({
    required this.id,
    required this.name,
    required this.catalogueIdentifiers,
    this.aliases = const [],
    required this.objectType,
    required this.rightAscension,
    required this.declination,
    this.apparentMagnitude,
    this.distanceLightYears,
    this.angularSizeMajorArcminutes,
    this.angularSizeMinorArcminutes,
    this.constellation,
    required this.description,
    required this.visibilityClass,
    required this.source,
    this.coordinateEpoch = 2000.0,
  });

  String get catalogueName => catalogueIdentifiers.join(' / ');

  factory DeepSkyObject.fromJson(Map<String, dynamic> json) {
    return DeepSkyObject(
      id: json['id'] as String,
      name: json['name'] as String,
      catalogueIdentifiers: (json['catalogueIds'] as List<dynamic>)
          .cast<String>(),
      aliases: (json['aliases'] as List<dynamic>? ?? const []).cast<String>(),
      objectType: json['type'] as String,
      rightAscension: (json['ra'] as num).toDouble(),
      declination: (json['dec'] as num).toDouble(),
      apparentMagnitude: (json['mag'] as num?)?.toDouble(),
      distanceLightYears: (json['distanceLy'] as num?)?.toDouble(),
      angularSizeMajorArcminutes: (json['sizeMajorArcmin'] as num?)?.toDouble(),
      angularSizeMinorArcminutes: (json['sizeMinorArcmin'] as num?)?.toDouble(),
      constellation: json['constellation'] as String?,
      description: json['description'] as String,
      visibilityClass: json['visibility'] as String,
      source: json['source'] as String,
      coordinateEpoch: (json['epoch'] as num?)?.toDouble() ?? 2000.0,
    );
  }
}
