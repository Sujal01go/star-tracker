import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/models/observation_time.dart';
import 'package:astro_track/models/observer_location.dart';
import 'package:astro_track/models/star.dart';

void main() {
  test('Compare Greenwich vs New Delhi', () {
    final starsFile = File('assets/catalogues/stars.json');
    final starsList = (jsonDecode(starsFile.readAsStringSync()) as List)
        .map((m) => Star.fromJson(m as Map<String, dynamic>))
        .toList();

    final time = ObservationTime(
      utcDateTime: DateTime.utc(2026, 11, 2, 20, 6),
      isRealTime: false,
    );

    final locGreenwich = ObserverLocation.greenwich;
    final engineG = AstronomyEngine(location: locGreenwich, time: time);
    final posG = engineG.computeBatch(starsList);

    print('=== Visible Stars from GREENWICH ===');
    final visibleG = starsList.where((s) => (posG[s.id]?.altitude ?? -90) > 15).toList();
    visibleG.sort((a, b) => a.apparentMagnitude.compareTo(b.apparentMagnitude));

    for (final s in visibleG.take(15)) {
      final pos = posG[s.id]!;
      print('${s.displayName.padRight(16)} (mag ${s.apparentMagnitude}): Az=${pos.azimuth.toStringAsFixed(1)}°, Alt=${pos.altitude.toStringAsFixed(1)}°');
    }
  });
}
