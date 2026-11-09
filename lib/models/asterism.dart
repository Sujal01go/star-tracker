/// A familiar star pattern, kept separate from official IAU constellations.
class Asterism {
  final String id;
  final String name;
  final List<List<String>> lines;
  final bool isMajor;

  const Asterism({
    required this.id,
    required this.name,
    required this.lines,
    this.isMajor = false,
  });

  factory Asterism.fromJson(Map<String, dynamic> json) => Asterism(
    id: json['id'] as String,
    name: json['name'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((line) => (line as List<dynamic>).cast<String>())
        .toList(growable: false),
    isMajor: json['major'] as bool? ?? false,
  );
}
