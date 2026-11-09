/// A single segment connecting two catalogue stars to form a constellation outline.
class ConstellationLine {
  final String starId1;
  final String starId2;

  const ConstellationLine({required this.starId1, required this.starId2});

  factory ConstellationLine.fromJson(List<dynamic> list) {
    return ConstellationLine(
      starId1: list[0] as String,
      starId2: list[1] as String,
    );
  }

  List<String> toJson() => [starId1, starId2];
}

/// Represents an astronomical constellation pattern and metadata.
class Constellation {
  /// Standard 3-letter IAU abbreviation (e.g. 'ORI', 'UMA', 'CAS').
  final String id;

  /// Latin or formal name (e.g. 'Orion', 'Ursa Major').
  final String name;

  /// Common or English name (e.g. 'The Hunter', 'The Great Bear').
  final String englishName;

  /// Approximate center Right Ascension in degrees (J2000.0).
  final double centerRa;

  /// Approximate center Declination in degrees (J2000.0).
  final double centerDec;

  /// Line segments connecting pairs of stars by their catalogue IDs.
  final List<ConstellationLine> lines;

  const Constellation({
    required this.id,
    required this.name,
    required this.englishName,
    required this.centerRa,
    required this.centerDec,
    required this.lines,
  });

  factory Constellation.fromJson(Map<String, dynamic> json) {
    return Constellation(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String? ?? json['name'] as String,
      centerRa: (json['centerRa'] as num).toDouble(),
      centerDec: (json['centerDec'] as num).toDouble(),
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => ConstellationLine.fromJson(e as List<dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'centerRa': centerRa,
      'centerDec': centerDec,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }
}
