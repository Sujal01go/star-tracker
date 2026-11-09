import 'package:flutter/material.dart';
import 'celestial_object.dart';

/// Represents a validated star from an astronomical catalogue.
class Star extends CelestialObject {
  final String? commonName;
  final String? bayerDesignation;
  final String? constellationId;
  final String? spectralType;
  final double? distanceLy;
  final double? parallaxMas;
  final double? properMotionRaMasYr;
  final double? properMotionDecMasYr;
  final double? colorIndexBv;
  final List<String> aliases;
  final String? description;
  final String? catalogueSource;
  final double coordinateEpoch;

  const Star({
    required super.id,
    super.name = '',
    this.commonName,
    this.bayerDesignation,
    this.constellationId,
    required super.rightAscension,
    required super.declination,
    required super.apparentMagnitude,
    this.spectralType,
    this.distanceLy,
    this.parallaxMas,
    this.properMotionRaMasYr,
    this.properMotionDecMasYr,
    this.colorIndexBv,
    this.aliases = const [],
    this.description,
    this.catalogueSource,
    this.coordinateEpoch = 2000.0,
  });

  /// Primary display name: common name if present, else Bayer designation, else catalogue ID.
  String get displayName {
    if (commonName != null && commonName!.trim().isNotEmpty) {
      return commonName!;
    }
    if (bayerDesignation != null && bayerDesignation!.trim().isNotEmpty) {
      return bayerDesignation!;
    }
    return id;
  }

  /// True if this is a prominent, well-known star.
  /// Constellation membership alone does not make every catalogue star prominent.
  bool get isFamous {
    if (apparentMagnitude <= 2.3) return true;

    final lowerNames = [
      commonName,
      name,
      ...aliases,
    ].whereType<String>().map((value) => value.toLowerCase().trim());

    const famousNames = {
      'polaris',
      'mintaka',
      'mizar',
      'algol',
      'alphecca',
      'phecda',
      'merak',
      'megrez',
      'kochab',
      'rasalhague',
      'eltanin',
      'rastaban',
      'denebola',
      'scheat',
      'markab',
      'algenib',
    };
    return lowerNames.any(famousNames.contains);
  }

  /// Estimates the natural star color based on spectral type or B-V index.
  /// O: deep blue-white (~30,000K)
  /// B: pale blue-white (~10,000-30,000K)
  /// A: pure white (~7,500-10,000K)
  /// F: yellow-white (~6,000-7,500K)
  /// G: warm yellow (~5,000-6,000K, Sun-like)
  /// K: orange (~3,500-5,000K)
  /// M: red-orange (~2,000-3,500K)
  Color get color {
    if (colorIndexBv != null) {
      final bv = colorIndexBv!;
      if (bv < -0.3) return const Color(0xFF9BB0FF);
      if (bv < 0.0) return const Color(0xFFBBCCFF);
      if (bv < 0.3) return const Color(0xFFF8F9FF);
      if (bv < 0.6) return const Color(0xFFFFF4E8);
      if (bv < 0.8) return const Color(0xFFFFE4B5);
      if (bv < 1.4) return const Color(0xFFFFB86C);
      return const Color(0xFFFF7A7A);
    }

    final spec = (spectralType ?? '').trim().toUpperCase();
    if (spec.startsWith('O')) return const Color(0xFF9EB5FF);
    if (spec.startsWith('B')) return const Color(0xFFC0D3FF);
    if (spec.startsWith('A')) return const Color(0xFFF4F7FF);
    if (spec.startsWith('F')) return const Color(0xFFFFF9E6);
    if (spec.startsWith('G')) return const Color(0xFFFFEAA7);
    if (spec.startsWith('K')) return const Color(0xFFFFBA7A);
    if (spec.startsWith('M')) return const Color(0xFFFF7B7B);
    return const Color(0xFFE8EEF5);
  }

  factory Star.fromJson(Map<String, dynamic> json) {
    return Star(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['commonName'] as String? ?? '',
      commonName: json['commonName'] as String?,
      bayerDesignation: json['bayer'] as String?,
      constellationId: json['con'] as String?,
      rightAscension: (json['ra'] as num).toDouble(),
      declination: (json['dec'] as num).toDouble(),
      apparentMagnitude: (json['mag'] as num).toDouble(),
      spectralType: json['spec'] as String?,
      distanceLy: (json['dist'] as num?)?.toDouble(),
      parallaxMas: (json['plx'] as num?)?.toDouble(),
      properMotionRaMasYr: (json['pmRa'] as num?)?.toDouble(),
      properMotionDecMasYr: (json['pmDec'] as num?)?.toDouble(),
      colorIndexBv: (json['bv'] as num?)?.toDouble(),
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((value) => value as String)
          .toList(growable: false),
      description: json['description'] as String?,
      catalogueSource: json['source'] as String?,
      coordinateEpoch: (json['epoch'] as num?)?.toDouble() ?? 2000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commonName': commonName,
      'bayer': bayerDesignation,
      'con': constellationId,
      'ra': rightAscension,
      'dec': declination,
      'mag': apparentMagnitude,
      'spec': spectralType,
      'dist': distanceLy,
      'plx': parallaxMas,
      'pmRa': properMotionRaMasYr,
      'pmDec': properMotionDecMasYr,
      'bv': colorIndexBv,
      'aliases': aliases,
      'description': description,
      'source': catalogueSource,
      'epoch': coordinateEpoch,
    };
  }
}
