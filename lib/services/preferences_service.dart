import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/observer_location.dart';
import '../rendering/star_rendering_style.dart';

/// Manages persistence of user settings, display preferences, and saved observer location.
class PreferencesService {
  static const _keyLocation = 'astro_saved_location';
  static const _keyNightMode = 'astro_night_mode';
  static const _keyConstellationLines = 'astro_constellation_lines';
  static const _keyConstellationNames = 'astro_constellation_names';
  static const _keyConstellationArt = 'astro_constellation_art';
  static const _keyHideLeastFamousStars = 'astro_hide_least_famous_stars';
  static const _keyCelestialGrid = 'astro_celestial_grid';
  static const _keyStarLabels = 'astro_star_labels';
  static const _keyLimitingMag = 'astro_limiting_magnitude';
  static const _keyHeadingOffset = 'astro_heading_offset';
  static const _keyInvertPitch = 'astro_invert_pitch';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  /// Loads saved observer location, defaulting to Greenwich if none is saved.
  ObserverLocation loadLocation() {
    final raw = _prefs.getString(_keyLocation);
    if (raw != null) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(raw) as Map<String, dynamic>;
        return ObserverLocation.fromJson(map);
      } catch (_) {}
    }
    return ObserverLocation.greenwich;
  }

  Future<void> saveLocation(ObserverLocation location) async {
    final raw = jsonEncode(location.toJson());
    await _prefs.setString(_keyLocation, raw);
  }

  /// Loads star rendering display preferences.
  StarRenderingStyle loadRenderingStyle() {
    final nightMode = _prefs.getBool(_keyNightMode) ?? false;
    final showLines = _prefs.getBool(_keyConstellationLines) ?? true;
    final showNames = _prefs.getBool(_keyConstellationNames) ?? true;
    final showArt = _prefs.getBool(_keyConstellationArt) ?? true;
    final hideLeastFamous = _prefs.getBool(_keyHideLeastFamousStars) ?? true;
    final showGrid = _prefs.getBool(_keyCelestialGrid) ?? true;
    final showLabels = _prefs.getBool(_keyStarLabels) ?? true;
    final limitMag = _prefs.getDouble(_keyLimitingMag) ?? 6.0;

    return StarRenderingStyle(
      nightMode: nightMode,
      showConstellationLines: showLines,
      showConstellationNames: showNames,
      showConstellationArt: showArt,
      showCelestialGrid: showGrid,
      showStarLabels: showLabels,
      hideLeastFamousStars: hideLeastFamous,
      limitingMagnitude: limitMag,
    );
  }

  Future<void> saveRenderingStyle(StarRenderingStyle style) async {
    await _prefs.setBool(_keyNightMode, style.nightMode);
    await _prefs.setBool(_keyConstellationLines, style.showConstellationLines);
    await _prefs.setBool(_keyConstellationNames, style.showConstellationNames);
    await _prefs.setBool(_keyConstellationArt, style.showConstellationArt);
    await _prefs.setBool(_keyHideLeastFamousStars, style.hideLeastFamousStars);
    await _prefs.setBool(_keyCelestialGrid, style.showCelestialGrid);
    await _prefs.setBool(_keyStarLabels, style.showStarLabels);
    await _prefs.setDouble(_keyLimitingMag, style.limitingMagnitude);
  }

  double loadHeadingOffset() {
    return _prefs.getDouble(_keyHeadingOffset) ?? 0.0;
  }

  Future<void> saveHeadingOffset(double offsetDegrees) async {
    await _prefs.setDouble(_keyHeadingOffset, offsetDegrees);
  }

  bool loadInvertPitch() {
    return _prefs.getBool(_keyInvertPitch) ?? false;
  }

  Future<void> saveInvertPitch(bool invert) async {
    await _prefs.setBool(_keyInvertPitch, invert);
  }
}
