import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/coordinate_transform.dart';
import 'package:astro_track/astronomy/star_position_calculator.dart';
import 'package:astro_track/data/asterism_catalogue.dart';
import 'package:astro_track/data/deep_sky_catalogue_repository.dart';
import 'package:astro_track/data/meteor_shower_catalogue.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/models/observer_location.dart';
import 'package:astro_track/models/observation_time.dart';

void main() {
  test('New star names use distinct, corrected HIP records', () {
    final repository = StarCatalogueRepository();

    expect(repository.allStars, hasLength(232));
    expect(repository.getStarById('HIP 1067')?.commonName, 'Algenib');
    expect(repository.getStarById('HIP 89931')?.commonName, 'Kaus Media');
    expect(repository.getStarById('HIP 90496')?.commonName, 'Kaus Borealis');
    expect(repository.getStarById('HIP 93506')?.commonName, 'Ascella');
    expect(repository.search('Rasalhague'), hasLength(1));
    expect(repository.search('Barnard Star'), hasLength(1));
  });

  test('All asterisms stay separate and reference catalogue stars', () {
    final ids = StarCatalogueRepository().allStars
        .map((star) => star.id)
        .toSet();

    expect(famousAsterisms, hasLength(10));
    for (final asterism in famousAsterisms) {
      for (final line in asterism.lines) {
        expect(line, hasLength(2));
        expect(ids, contains(line[0]), reason: asterism.name);
        expect(ids, contains(line[1]), reason: asterism.name);
      }
    }
  });

  test('Deep-sky catalogue finds Messier aliases and named targets', () {
    final repository = DeepSkyCatalogueRepository();

    expect(repository.allObjects, hasLength(46));
    expect(repository.search('M42').single.name, 'Orion Nebula');
    expect(repository.search('Pleiades').single.id, 'M45');
    expect(repository.search('Horsehead').single.id, 'B 33');
    expect(repository.search('Northern Coalsack').single.id, 'Cygnus Rift');
    expect(repository.getById('NGC 2237')?.aliases, isEmpty);
  });

  test(
    'Batch star positions include the same proper motion as single positions',
    () {
      final star = StarCatalogueRepository().getStarById('HIP 87937')!;
      final location = ObserverLocation.newDelhi;
      final time = ObservationTime(
        utcDateTime: DateTime.utc(2025, 1, 1),
        isRealTime: false,
      );

      final single = StarPositionCalculator.computePosition(
        star: star,
        location: location,
        time: time,
        applyRefraction: false,
      );
      final batch = StarPositionCalculator.computeBatchPositions(
        stars: [star],
        location: location,
        time: time,
        applyRefraction: false,
      )[star.id]!;

      expect(batch.azimuth, closeTo(single.azimuth, 1e-8));
      expect(batch.altitude, closeTo(single.altitude, 1e-8));
    },
  );

  test('Galactic coordinate conversion maps the Galactic Center correctly', () {
    final center = CoordinateTransform.galacticToEquatorial(
      longitudeDeg: 0,
      latitudeDeg: 0,
    );

    expect(center.rightAscension, closeTo(266.405, 0.01));
    expect(center.declination, closeTo(-28.936, 0.01));
  });

  test('Meteor shower radiants are active only during their annual dates', () {
    final perseids = meteorShowers.singleWhere(
      (shower) => shower.id == 'perseids',
    );
    expect(perseids.isActive(DateTime.utc(2026, 8, 12)), isTrue);
    expect(perseids.isActive(DateTime.utc(2026, 2, 12)), isFalse);
  });
}
