import 'package:flutter/material.dart';
import 'celestial_object.dart';

/// Major Solar System bodies.
enum PlanetType {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
  earth,
  dwarfPlanet,
  asteroid,
  comet,
  galileanMoon,
}

/// Represents a dynamically computed Solar System planet, the Sun, or the Moon.
class Planet extends CelestialObject {
  final PlanetType type;
  final String symbol;
  final double eclipticLongitude; // in degrees [0, 360)
  final double eclipticLatitude; // in degrees [-90, +90]
  final double
  distanceAu; // distance from Earth in Astronomical Units (or km for Moon)
  final double illuminatedFraction; // 0.0 (New) to 1.0 (Full)
  final String phaseName; // e.g. "Waxing Crescent", "Full Moon"
  final double angularDiameterArcsec;
  final Color baseColor;
  final String? ephemerisSource;
  final String? description;

  const Planet({
    required super.id,
    required super.name,
    required this.type,
    required this.symbol,
    required super.rightAscension,
    required super.declination,
    required super.apparentMagnitude,
    required this.eclipticLongitude,
    required this.eclipticLatitude,
    required this.distanceAu,
    required this.illuminatedFraction,
    required this.phaseName,
    required this.angularDiameterArcsec,
    required this.baseColor,
    this.ephemerisSource,
    this.description,
  });

  /// True if this object is the Sun or the Moon.
  bool get isSun => type == PlanetType.sun;
  bool get isMoon => type == PlanetType.moon;
  bool get isGalileanMoon => type == PlanetType.galileanMoon;
  bool get isDwarfPlanet =>
      type == PlanetType.dwarfPlanet || type == PlanetType.pluto;

  /// Distance in millions of kilometers.
  double get distanceMillionKm => distanceAu * 149.5978707;
}
