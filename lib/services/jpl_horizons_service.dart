import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef EquatorialCoordinates = ({double rightAscension, double declination});

/// One timestamped JPL snapshot. Keeping the source time lets the engine fall
/// back to its local ephemeris as soon as a cached result becomes stale.
class HorizonsCoordinateSnapshot {
  final DateTime observationTime;
  final Map<String, EquatorialCoordinates> coordinates;

  const HorizonsCoordinateSnapshot({
    required this.observationTime,
    required this.coordinates,
  });
}

/// Fetches apparent geocentric coordinates from JPL Horizons.
///
/// Results are requested sequentially, cached locally, and refined by the
/// app's local ephemeris whenever this service is unavailable or stale.
class JplHorizonsService {
  static const _endpoint = 'https://ssd.jpl.nasa.gov/api/horizons.api';
  static const _cacheKey = 'jpl_horizons_snapshot_v1';
  static const _apiVersion = '1.0';
  static const _userAgent =
      'AstroTrack/1.0.0 (https://github.com/Sujal01go/star-tracker/issues)';
  static const _liveCacheWindow = Duration(minutes: 9);
  static const _manualCacheWindow = Duration(seconds: 1);

  // Major bodies, numbered asteroids/dwarf planets, Jupiter's four Galilean
  // moons, and 1P/Halley (the Horizons small-body record number is 90000001).
  static const _targets = <String, String>{
    'SUN': '10',
    'MOON': '301',
    'MER': '199',
    'VEN': '299',
    'MAR': '499',
    'JUP': '599',
    'SAT': '699',
    'URA': '799',
    'NEP': '899',
    'PLU': '999',
    'CER': '1;',
    'VES': '4;',
    'PAL': '2;',
    'JUN': '3;',
    'ERI': '136199;',
    'HAU': '136108;',
    'MAK': '136472;',
    'HALLEY': '90000001;',
    'IO': '501',
    'EUROPA': '502',
    'GANYMEDE': '503',
    'CALLISTO': '504',
  };

  // JPL's fair-use guidance asks automated clients to issue one request at a
  // time. This small queue also keeps that true if another screen creates a
  // second service instance later.
  static Future<void> _requestTail = Future<void>.value();

  Future<HorizonsCoordinateSnapshot> fetchSolarSystemCoordinates(
    DateTime observationTime, {
    bool allowRecentCache = false,
  }) async {
    final utc = observationTime.toUtc();
    final cached = await _readCache();
    final cacheWindow = allowRecentCache
        ? _liveCacheWindow
        : _manualCacheWindow;
    if (cached != null &&
        utc.difference(cached.observationTime).abs() <= cacheWindow) {
      return cached;
    }

    final coordinates = <String, EquatorialCoordinates>{};
    for (final entry in _targets.entries) {
      try {
        coordinates[entry.key] = await _fetchTarget(entry.value, utc);
      } on _HorizonsHttpException catch (error) {
        // A missing target can be skipped. Server overload and transport
        // failures stop the batch immediately; there are no automatic retries.
        if (error.statusCode == 404) continue;
        break;
      } on FormatException {
        break;
      } catch (_) {
        break;
      }
    }

    final snapshot = HorizonsCoordinateSnapshot(
      observationTime: utc,
      coordinates: Map.unmodifiable(coordinates),
    );
    if (coordinates.length == _targets.length) {
      await _writeCache(snapshot);
    }
    return snapshot;
  }

  Future<EquatorialCoordinates> _fetchTarget(
    String targetId,
    DateTime utc,
  ) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'format': 'json',
        'COMMAND': "'$targetId'",
        'OBJ_DATA': "'NO'",
        'MAKE_EPHEM': "'YES'",
        'EPHEM_TYPE': "'OBSERVER'",
        'CENTER': "'500@399'",
        'TLIST': "'${_calendarTime(utc)}'",
        'TLIST_TYPE': "'CAL'",
        'QUANTITIES': "'2'",
        'ANG_FORMAT': "'DEG'",
        'TIME_TYPE': "'UT'",
        'CSV_FORMAT': "'YES'",
      },
    );

    final response = await _getSerially(uri);
    if (response.statusCode != 200) {
      throw _HorizonsHttpException(response.statusCode);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final signature = payload['signature'];
    if (signature is! Map<String, dynamic> ||
        signature['version'] != _apiVersion) {
      throw const FormatException(
        'JPL Horizons API response version changed; skipping this refresh.',
      );
    }
    final apiError = payload['error'];
    if (apiError != null) {
      throw FormatException('JPL Horizons error: $apiError');
    }

    final result = payload['result'];
    if (result is! String) {
      throw const FormatException('JPL Horizons response has no result table.');
    }

    final start = result.indexOf(r'$$SOE');
    final end = result.indexOf(r'$$EOE', start);
    if (start < 0 || end < 0) {
      throw const FormatException('JPL Horizons returned no coordinate row.');
    }

    final rows = result
        .substring(start + r'$$SOE'.length, end)
        .trim()
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty);
    final row = rows.firstOrNull;
    if (row == null) {
      throw const FormatException('JPL Horizons returned an empty table.');
    }

    // Quantity 2 emits: date, two marker fields, apparent RA, Dec.
    final fields = row.split(',').map((field) => field.trim()).toList();
    if (fields.length < 5) {
      throw const FormatException('JPL Horizons coordinate row is malformed.');
    }
    final rightAscension = double.tryParse(fields[3]);
    final declination = double.tryParse(fields[4]);
    if (rightAscension == null || declination == null) {
      throw const FormatException('JPL Horizons coordinates are not numeric.');
    }

    return (rightAscension: rightAscension, declination: declination);
  }

  Future<http.Response> _getSerially(Uri uri) async {
    final previous = _requestTail;
    final release = Completer<void>();
    _requestTail = release.future;
    await previous;
    try {
      return await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 12));
    } finally {
      release.complete();
    }
  }

  Future<HorizonsCoordinateSnapshot?> _readCache() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final time = DateTime.parse(json['observationTime'] as String).toUtc();
      final rawCoordinates = json['coordinates'] as Map<String, dynamic>;
      final coordinates = <String, EquatorialCoordinates>{};
      for (final entry in rawCoordinates.entries) {
        final value = entry.value as Map<String, dynamic>;
        final ra = (value['ra'] as num).toDouble();
        final dec = (value['dec'] as num).toDouble();
        if (ra.isFinite && dec.isFinite) {
          coordinates[entry.key] = (rightAscension: ra, declination: dec);
        }
      }
      return HorizonsCoordinateSnapshot(
        observationTime: time,
        coordinates: Map.unmodifiable(coordinates),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(HorizonsCoordinateSnapshot snapshot) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _cacheKey,
        jsonEncode({
          'observationTime': snapshot.observationTime.toIso8601String(),
          'coordinates': {
            for (final entry in snapshot.coordinates.entries)
              entry.key: {
                'ra': entry.value.rightAscension,
                'dec': entry.value.declination,
              },
          },
        }),
      );
    } catch (_) {
      // The local ephemeris remains available if preferences cannot be written.
    }
  }

  String _calendarTime(DateTime utc) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}-${twoDigits(utc.month)}-${twoDigits(utc.day)} '
        '${twoDigits(utc.hour)}:${twoDigits(utc.minute)}:${twoDigits(utc.second)}';
  }
}

class _HorizonsHttpException implements Exception {
  final int statusCode;

  const _HorizonsHttpException(this.statusCode);
}
