import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/constellation.dart';
import '../models/constellation_boundary.dart';
import 'default_constellations_data.dart';

/// Repository for managing constellation asterisms and outlines.
class ConstellationRepository {
  List<Constellation> _constellations = _initAll88Constellations();
  List<ConstellationBoundary> _boundaries = const [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Constellation> get allConstellations => _constellations;
  List<ConstellationBoundary> get boundaries => _boundaries;

  static List<Constellation> _initAll88Constellations() {
    try {
      final List<dynamic> jsonList =
          jsonDecode(all88ConstellationsJson) as List<dynamic>;
      return jsonList
          .map((item) => Constellation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultConstellations;
    }
  }

  /// Loads constellation patterns from bundled asset.
  Future<void> loadConstellations([
    String assetPath = 'assets/constellations/constellations.json',
  ]) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _constellations = jsonList
          .map((item) => Constellation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Retain the initialized 88 constellations
    }
    try {
      final jsonString = await rootBundle.loadString(
        'assets/constellations/iau_boundaries.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _boundaries = jsonList
          .map(
            (item) =>
                ConstellationBoundary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } catch (_) {
      // The constellation line art remains available if the optional overlay
      // asset cannot be loaded.
    }
    _isLoaded = true;
  }

  Constellation? getConstellationById(String id) {
    final query = id.trim().toUpperCase();
    try {
      return _constellations.firstWhere(
        (c) =>
            c.id.toUpperCase() == query ||
            c.name.toUpperCase() == query ||
            c.englishName.toUpperCase() == query,
      );
    } catch (_) {
      return null;
    }
  }

  static const List<Constellation> _defaultConstellations = [
    Constellation(
      id: 'ORI',
      name: 'Orion',
      englishName: 'The Hunter',
      centerRa: 83.8,
      centerDec: -5.4,
      lines: [
        ConstellationLine(
          starId1: 'HIP 27989',
          starId2: 'HIP 25336',
        ), // Betelgeuse - Bellatrix
        ConstellationLine(
          starId1: 'HIP 25336',
          starId2: 'HIP 25930',
        ), // Bellatrix - Mintaka
        ConstellationLine(
          starId1: 'HIP 25930',
          starId2: 'HIP 26311',
        ), // Mintaka - Alnilam
        ConstellationLine(
          starId1: 'HIP 26311',
          starId2: 'HIP 26727',
        ), // Alnilam - Alnitak
        ConstellationLine(
          starId1: 'HIP 26727',
          starId2: 'HIP 27366',
        ), // Alnitak - Saiph
        ConstellationLine(
          starId1: 'HIP 27366',
          starId2: 'HIP 24436',
        ), // Saiph - Rigel
        ConstellationLine(
          starId1: 'HIP 24436',
          starId2: 'HIP 25930',
        ), // Rigel - Mintaka
        ConstellationLine(
          starId1: 'HIP 27989',
          starId2: 'HIP 26727',
        ), // Betelgeuse - Alnitak
      ],
    ),
    Constellation(
      id: 'UMA',
      name: 'Ursa Major',
      englishName: 'The Great Bear',
      centerRa: 175.0,
      centerDec: 55.0,
      lines: [
        ConstellationLine(
          starId1: 'HIP 54061',
          starId2: 'HIP 53910',
        ), // Dubhe - Merak
        ConstellationLine(
          starId1: 'HIP 53910',
          starId2: 'HIP 58001',
        ), // Merak - Phecda
        ConstellationLine(
          starId1: 'HIP 58001',
          starId2: 'HIP 59774',
        ), // Phecda - Megrez
        ConstellationLine(
          starId1: 'HIP 59774',
          starId2: 'HIP 54061',
        ), // Megrez - Dubhe
        ConstellationLine(
          starId1: 'HIP 59774',
          starId2: 'HIP 62956',
        ), // Megrez - Alioth
        ConstellationLine(
          starId1: 'HIP 62956',
          starId2: 'HIP 65378',
        ), // Alioth - Mizar
        ConstellationLine(
          starId1: 'HIP 65378',
          starId2: 'HIP 67301',
        ), // Mizar - Alkaid
      ],
    ),
    Constellation(
      id: 'CAS',
      name: 'Cassiopeia',
      englishName: 'The Queen',
      centerRa: 15.0,
      centerDec: 60.0,
      lines: [
        ConstellationLine(
          starId1: 'HIP 746',
          starId2: 'HIP 3179',
        ), // Caph - Schedar
        ConstellationLine(
          starId1: 'HIP 3179',
          starId2: 'HIP 4427',
        ), // Schedar - Gamma Cas
        ConstellationLine(
          starId1: 'HIP 4427',
          starId2: 'HIP 6537',
        ), // Gamma Cas - Ruchbah
        ConstellationLine(
          starId1: 'HIP 6537',
          starId2: 'HIP 8582',
        ), // Ruchbah - Segin
      ],
    ),
    Constellation(
      id: 'CRU',
      name: 'Crux',
      englishName: 'The Southern Cross',
      centerRa: 187.0,
      centerDec: -60.0,
      lines: [
        ConstellationLine(
          starId1: 'HIP 60718',
          starId2: 'HIP 61084',
        ), // Acrux - Gacrux
        ConstellationLine(
          starId1: 'HIP 62434',
          starId2: 'HIP 59747',
        ), // Mimosa - Delta Crucis
      ],
    ),
  ];
}
