import 'package:flutter/foundation.dart';
import '../models/constellation.dart';
import '../models/observer_location.dart';
import '../models/observation_time.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import 'astronomical_time.dart';
import 'coordinate_transform.dart';
import 'planetary_ephemeris.dart';
import 'sidereal_time.dart';
import 'star_position_calculator.dart';

/// Central astronomy engine for AstroTrack.
/// Manages time, location, sidereal calculation, planetary ephemerides, and coordinate transformations.
class AstronomyEngine extends ChangeNotifier {
  ObserverLocation _location;
  ObservationTime _time;
  bool _applyPrecession = true;
  bool _applyRefraction = false;

  List<Planet> _planets = [];
  List<Planet> _additionalBodies = [];
  Map<String, SkyPosition> _planetPositions = {};
  Map<String, SkyPosition> _additionalBodyPositions = {};

  AstronomyEngine({ObserverLocation? location, ObservationTime? time})
    : _location = location ?? ObserverLocation.greenwich,
      _time = time ?? ObservationTime.now() {
    _recomputePlanets();
  }

  ObserverLocation get location => _location;
  ObservationTime get time => _time;
  bool get applyPrecession => _applyPrecession;
  bool get applyRefraction => _applyRefraction;
  List<Planet> get planets => _planets;
  List<Planet> get additionalBodies => _additionalBodies;
  List<Planet> get solarSystemObjects => [..._planets, ..._additionalBodies];
  Map<String, SkyPosition> get planetPositions => _planetPositions;
  Map<String, SkyPosition> get additionalBodyPositions =>
      _additionalBodyPositions;
  Map<String, SkyPosition> get solarSystemPositions => {
    ..._planetPositions,
    ..._additionalBodyPositions,
  };

  /// Current Julian Date.
  double get currentJulianDate =>
      AstronomicalTime.julianDate(_time.utcDateTime);

  /// Current Greenwich Mean Sidereal Time in degrees.
  double get currentGmst =>
      SiderealTime.greenwichMeanSiderealTime(currentJulianDate);

  /// Current Local Sidereal Time in degrees for the active observer.
  double get currentLst =>
      SiderealTime.localSiderealTime(currentGmst, _location.longitude);

  /// Current Local Sidereal Time formatted as HH:MM:SS.
  String get formattedLst {
    final hoursTotal = currentLst / 15.0;
    final h = hoursTotal.floor();
    final m = ((hoursTotal - h) * 60.0).floor();
    final s = ((((hoursTotal - h) * 60.0) - m) * 60.0).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _recomputePlanets() {
    _planets = PlanetaryEphemeris.computeAllPlanets(_time.utcDateTime);
    _additionalBodies = PlanetaryEphemeris.computeAdditionalBodies(
      _time.utcDateTime,
    );
    final lst = currentLst;
    final lat = _location.latitude;

    final Map<String, SkyPosition> majorPositions = {};
    final Map<String, SkyPosition> additionalPositions = {};
    for (final p in _planets) {
      majorPositions[p.id] = CoordinateTransform.equatorialToHorizontal(
        raDeg: p.rightAscension,
        decDeg: p.declination,
        latitudeDeg: lat,
        lstDeg: lst,
        applyRefraction: _applyRefraction,
      );
    }
    for (final p in _additionalBodies) {
      additionalPositions[p.id] = CoordinateTransform.equatorialToHorizontal(
        raDeg: p.rightAscension,
        decDeg: p.declination,
        latitudeDeg: lat,
        lstDeg: lst,
        applyRefraction: _applyRefraction,
      );
    }
    _planetPositions = majorPositions;
    _additionalBodyPositions = additionalPositions;
  }

  Planet? getPlanetById(String id) {
    try {
      final upper = id.toUpperCase();
      return solarSystemObjects.firstWhere(
        (p) => p.id.toUpperCase() == upper || p.name.toUpperCase() == upper,
      );
    } catch (_) {
      return null;
    }
  }

  void updateLocation(ObserverLocation newLocation) {
    if (_location != newLocation) {
      _location = newLocation;
      _recomputePlanets();
      notifyListeners();
    }
  }

  void updateTime(ObservationTime newTime) {
    _time = newTime;
    _recomputePlanets();
    notifyListeners();
  }

  void setPrecessionEnabled(bool enabled) {
    if (_applyPrecession != enabled) {
      _applyPrecession = enabled;
      _recomputePlanets();
      notifyListeners();
    }
  }

  void setRefractionEnabled(bool enabled) {
    if (_applyRefraction != enabled) {
      _applyRefraction = enabled;
      _recomputePlanets();
      notifyListeners();
    }
  }

  /// Computes the horizontal sky position for a star.
  SkyPosition computeStarPosition(Star star) {
    return StarPositionCalculator.computePosition(
      star: star,
      location: _location,
      time: _time,
      applyPrecession: _applyPrecession,
      applyRefraction: _applyRefraction,
    );
  }

  /// Computes batch horizontal sky positions for a catalogue of stars.
  Map<String, SkyPosition> computeBatch(List<Star> stars) {
    return StarPositionCalculator.computeBatchPositions(
      stars: stars,
      location: _location,
      time: _time,
      applyPrecession: _applyPrecession,
      applyRefraction: _applyRefraction,
    );
  }

  /// Converts any equatorial coordinate (RA, Dec) to local (Az, Alt).
  SkyPosition equatorialToHorizontal(double raDeg, double decDeg) {
    return CoordinateTransform.equatorialToHorizontal(
      raDeg: raDeg,
      decDeg: decDeg,
      latitudeDeg: _location.latitude,
      lstDeg: currentLst,
      applyRefraction: _applyRefraction,
    );
  }

  /// Computes a current horizontal position from catalogue coordinates.
  /// Catalogue coordinates are J2000 unless another epoch is supplied.
  SkyPosition computeFixedPosition(
    double raDeg,
    double decDeg, {
    double coordinateEpoch = 2000.0,
  }) {
    var ra = raDeg;
    var dec = decDeg;
    final t = AstronomicalTime.julianCenturiesJ2000(currentJulianDate);
    if (_applyPrecession && coordinateEpoch == 2000.0 && t.abs() > 0.0001) {
      final precessed = CoordinateTransform.applyPrecessionJ2000(
        raDeg: ra,
        decDeg: dec,
        tCenturies: t,
      );
      ra = precessed.rightAscension;
      dec = precessed.declination;
    }
    return CoordinateTransform.equatorialToHorizontal(
      raDeg: ra,
      decDeg: dec,
      latitudeDeg: _location.latitude,
      lstDeg: currentLst,
      applyRefraction: _applyRefraction,
    );
  }

  /// Current horizontal positions along the IAU Galactic equator.
  List<SkyPosition> computeGalacticPlanePositions() {
    return [
      for (double longitude = 0; longitude <= 360; longitude += 5)
        () {
          final equatorial = CoordinateTransform.galacticToEquatorial(
            longitudeDeg: longitude,
            latitudeDeg: 0,
          );
          return computeFixedPosition(
            equatorial.rightAscension,
            equatorial.declination,
          );
        }(),
    ];
  }

  /// Computes horizontal sky positions for a catalogue of constellations.
  Map<String, SkyPosition> computeConstellationPositions(
    List<Constellation> constellations,
  ) {
    final lst = currentLst;
    final lat = _location.latitude;
    final t = AstronomicalTime.julianCenturiesJ2000(currentJulianDate);
    final Map<String, SkyPosition> result = {};

    for (final c in constellations) {
      double ra = c.centerRa;
      double dec = c.centerDec;
      if (_applyPrecession && t.abs() > 0.001) {
        final prec = CoordinateTransform.applyPrecessionJ2000(
          raDeg: ra,
          decDeg: dec,
          tCenturies: t,
        );
        ra = prec.rightAscension;
        dec = prec.declination;
      }
      result[c.id] = CoordinateTransform.equatorialToHorizontal(
        raDeg: ra,
        decDeg: dec,
        latitudeDeg: lat,
        lstDeg: lst,
        applyRefraction: false,
      );
    }
    return result;
  }
}
