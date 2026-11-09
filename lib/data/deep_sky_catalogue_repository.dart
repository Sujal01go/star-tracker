import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/deep_sky_object.dart';
import 'default_deep_sky_data.dart';

/// Offline catalogue for the curated Messier, NGC, IC and named deep-sky set.
class DeepSkyCatalogueRepository {
  List<DeepSkyObject> _objects = _decode(allDeepSkyObjectsJson);
  Map<String, DeepSkyObject> _byId = {};

  DeepSkyCatalogueRepository() {
    _index();
  }

  static List<DeepSkyObject> _decode(String source) {
    final rows = jsonDecode(source) as List<dynamic>;
    return rows
        .map((row) => DeepSkyObject.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  List<DeepSkyObject> get allObjects => _objects;

  void _index() {
    _byId = {for (final object in _objects) object.id.toLowerCase(): object};
  }

  Future<void> loadCatalogue([
    String assetPath = 'assets/catalogues/deep_sky.json',
  ]) async {
    try {
      _objects = _decode(await rootBundle.loadString(assetPath));
      _index();
    } catch (_) {
      // The generated Dart copy keeps the catalogue available offline.
    }
  }

  DeepSkyObject? getById(String id) => _byId[id.trim().toLowerCase()];

  List<DeepSkyObject> search(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return _objects;
    return _objects
        .where((object) {
          return object.id.toLowerCase().contains(term) ||
              object.name.toLowerCase().contains(term) ||
              object.objectType.toLowerCase().contains(term) ||
              object.catalogueIdentifiers.any(
                (id) => id.toLowerCase().contains(term),
              ) ||
              object.aliases.any((alias) => alias.toLowerCase().contains(term));
        })
        .toList(growable: false);
  }
}
