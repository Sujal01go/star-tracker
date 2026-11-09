import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/models/observation_time.dart';
import 'package:astro_track/models/observer_location.dart';
import 'package:astro_track/models/star.dart';

void main() {
  test('Verify visible sky and coordinates', () {
    final starsFile = File('assets/catalogues/stars.json');
    final starsList = (jsonDecode(starsFile.readAsStringSync()) as List)
        .map((m) => Star.fromJson(m as Map<String, dynamic>))
        .toList();

    final time = ObservationTime(
      utcDateTime: DateTime.utc(2026, 11, 2, 20, 6),
      isRealTime: false,
    );

    final locIndia = ObserverLocation.newDelhi;
    final engineIndia = AstronomyEngine(location: locIndia, time: time);
    final positionsIndia = engineIndia.computeBatch(starsList);

    print('=== Visible Stars (Alt > 15°) from New Delhi at 01:36 AM, Nov 3 ===');
    final visible = starsList.where((s) => (positionsIndia[s.id]?.altitude ?? -90) > 15).toList();
    visible.sort((a, b) => a.apparentMagnitude.compareTo(b.apparentMagnitude));

    for (final s in visible.take(25)) {
      final pos = positionsIndia[s.id]!;
      print('${s.displayName.padRight(16)} (mag ${s.apparentMagnitude}): Az=${pos.azimuth.toStringAsFixed(1)}°, Alt=${pos.altitude.toStringAsFixed(1)}°');
    }

    print('\n=== Planets at 01:36 AM ===');
    for (final p in engineIndia.planets) {
      final pos = engineIndia.planetPositions[p.id]!;
      print('${p.name.padRight(16)} (mag ${p.apparentMagnitude.toStringAsFixed(1)}): Az=${pos.azimuth.toStringAsFixed(1)}°, Alt=${pos.altitude.toStringAsFixed(1)}°');
    }
  });
}
