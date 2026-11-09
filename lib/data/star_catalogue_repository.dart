import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/star.dart';
import 'default_stars_data.dart';
import 'local_star_catalogue.dart';

/// Repository for managing and querying astronomical star catalogues.
class StarCatalogueRepository {
  List<Star> _stars = _initAllCatalogueStars();
  Map<String, Star> _starsById = {};
  bool _isLoaded = true;

  StarCatalogueRepository() {
    _indexStars();
  }

  static List<Star> _initAllCatalogueStars() {
    try {
      final List<dynamic> jsonList =
          jsonDecode(allCatalogueStarsJson) as List<dynamic>;
      return jsonList
          .map((item) => Star.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return LocalStarCatalogue.defaultStars;
    }
  }

  bool get isLoaded => _isLoaded;
  List<Star> get allStars => _stars;

  void _indexStars() {
    _starsById = {for (final star in _stars) star.id: star};
  }

  /// Loads the full catalogue from local asset storage.
  /// Falls back to pre-compiled [allCatalogueStarsJson] if offline or asset loading fails.
  Future<void> loadCatalogue([
    String assetPath = 'assets/catalogues/stars.json',
  ]) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _stars = jsonList
          .map((item) => Star.fromJson(item as Map<String, dynamic>))
          .toList();
      _indexStars();
      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// Retrieves a star by its stable catalogue ID (e.g. "HIP 32349").
  Star? getStarById(String id) => _starsById[id];

  /// Filters stars by maximum visual magnitude (brighter than or equal to [maxMagnitude]).
  List<Star> getStarsWithMagnitudeLimit(double maxMagnitude) {
    return _stars.where((s) => s.apparentMagnitude <= maxMagnitude).toList();
  }

  /// Searches for stars matching a query against common name, Bayer designation,
  /// constellation, or catalogue identifier.
  List<Star> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return _stars;

    return _stars.where((star) {
      if (star.id.toLowerCase().contains(clean)) {
        return true;
      }
      if (star.commonName != null &&
          star.commonName!.toLowerCase().contains(clean)) {
        return true;
      }
      if (star.bayerDesignation != null &&
          star.bayerDesignation!.toLowerCase().contains(clean)) {
        return true;
      }
      if (star.aliases.any((alias) => alias.toLowerCase().contains(clean)) ||
          star.name.toLowerCase().contains(clean)) {
        return true;
      }
      if (star.constellationId != null &&
          star.constellationId!.toLowerCase() == clean) {
        return true;
      }
      return false;
    }).toList();
  }
}
