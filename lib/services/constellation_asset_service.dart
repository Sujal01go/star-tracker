import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service managing constellation mythological artwork, asset paths, and cached ui.Image instances.
class ConstellationAssetService {
  static const String defaultArtwork =
      'assets/images/constellations/default_constellation.png';

  static const Map<String, String> _constellationArtMap = {
    'ori': 'assets/images/constellations/orion.png',
    'orion': 'assets/images/constellations/orion.png',
    'uma': 'assets/images/constellations/ursa_major.png',
    'ursa major': 'assets/images/constellations/ursa_major.png',
    'umi': 'assets/images/constellations/ursa_minor.png',
    'ursa minor': 'assets/images/constellations/ursa_minor.png',
    'cas': 'assets/images/constellations/cassiopeia.png',
    'cassiopeia': 'assets/images/constellations/cassiopeia.png',
    'cyg': 'assets/images/constellations/cygnus.png',
    'cygnus': 'assets/images/constellations/cygnus.png',
    'cma': 'assets/images/constellations/canis_major.png',
    'canis major': 'assets/images/constellations/canis_major.png',
    'tau': 'assets/images/constellations/taurus.png',
    'taurus': 'assets/images/constellations/taurus.png',
    'sco': 'assets/images/constellations/scorpius.png',
    'scorpius': 'assets/images/constellations/scorpius.png',
    'leo': 'assets/images/constellations/leo.png',
    'lion': 'assets/images/constellations/leo.png',
    'gem': 'assets/images/constellations/gemini.png',
    'gemini': 'assets/images/constellations/gemini.png',
    'peg': 'assets/images/constellations/pegasus.png',
    'pegasus': 'assets/images/constellations/pegasus.png',
    'and': 'assets/images/constellations/andromeda.png',
    'andromeda': 'assets/images/constellations/andromeda.png',
    'sgr': 'assets/images/constellations/sagittarius.png',
    'sagittarius': 'assets/images/constellations/sagittarius.png',
    'cru': 'assets/images/constellations/crux.png',
    'crux': 'assets/images/constellations/crux.png',
    'southern cross': 'assets/images/constellations/crux.png',
    'aql': 'assets/images/constellations/aquila.png',
    'aquila': 'assets/images/constellations/aquila.png',
    'lyr': 'assets/images/constellations/lyra.png',
    'lyra': 'assets/images/constellations/lyra.png',
    'boo': 'assets/images/constellations/bootes.png',
    'bootes': 'assets/images/constellations/bootes.png',
  };

  /// Returns whether a constellation has a dedicated artwork.
  static bool hasArtwork(String? idOrName) {
    if (idOrName == null || idOrName.trim().isEmpty) return false;
    final key = idOrName.trim().toLowerCase();
    return _constellationArtMap.containsKey(key);
  }

  /// Returns the asset path for a constellation by its IAU 3-letter code or full name.
  static String getArtworkForConstellation(String? idOrName) {
    if (idOrName == null || idOrName.trim().isEmpty) return defaultArtwork;
    final key = idOrName.trim().toLowerCase();
    return _constellationArtMap[key] ?? defaultArtwork;
  }

  // Preloaded ui.Image cache for Canvas painting
  static final Map<String, ui.Image> _uiImageCache = {};
  static Future<void>? _loadingImages;

  static Map<String, ui.Image> get uiImages => _uiImageCache;

  /// Loads constellation artwork into memory as dart:ui.Image objects.
  static Future<void> preloadUiImages() {
    if (_uiImageCache.containsKey('default')) return Future.value();
    return _loadingImages ??= _loadUiImages();
  }

  static Future<void> _loadUiImages() async {
    final distinctPaths = {..._constellationArtMap.values, defaultArtwork};

    try {
      final loadedImages = <String, ui.Image>{};
      await Future.wait(
        distinctPaths.map((path) async {
          try {
            final data = await rootBundle.load(path);
            final codec = await ui.instantiateImageCodec(
              data.buffer.asUint8List(),
            );
            final frameInfo = await codec.getNextFrame();
            loadedImages[path] = frameInfo.image;
          } catch (e) {
            debugPrint('Could not load constellation ui.Image for $path: $e');
          }
        }),
      );

      _uiImageCache.addAll(loadedImages);

      // Populate aliases only after the complete artwork batch has loaded.
      for (final entry in _constellationArtMap.entries) {
        final img = loadedImages[entry.value];
        if (img != null) {
          _uiImageCache[entry.key] = img;
        }
      }
      final defaultImg = loadedImages[defaultArtwork];
      if (defaultImg != null) {
        _uiImageCache['default'] = defaultImg;
      }
    } finally {
      _loadingImages = null;
    }
  }

  static ui.Image? getUiImage(String? idOrName) {
    final path = getArtworkForConstellation(idOrName);
    return _uiImageCache[path] ?? _uiImageCache[defaultArtwork];
  }
}
