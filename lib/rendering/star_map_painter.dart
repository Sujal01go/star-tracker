import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/asterism.dart';
import '../models/constellation.dart';
import '../models/deep_sky_object.dart';
import '../models/meteor_shower.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import 'sky_projection.dart';
import 'star_rendering_style.dart';

/// High-performance CustomPainter for rendering stars, planets, Sun, Moon, constellation outlines,
/// coordinate grids, and horizons.
class StarMapPainter extends CustomPainter {
  final List<Star> stars;
  final Map<String, SkyPosition> starPositions;
  final List<Planet> planets;
  final Map<String, SkyPosition> planetPositions;
  final Map<PlanetType, ui.Image>? planetImages;
  final List<Constellation> constellations;
  final Map<String, SkyPosition> constellationPositions;
  final List<List<SkyPosition>> constellationBoundaryPositions;
  final Map<String, ui.Image>? constellationImages;
  final List<DeepSkyObject> deepSkyObjects;
  final Map<String, SkyPosition> deepSkyPositions;
  final List<Asterism> asterisms;
  final List<MeteorShower> activeMeteorShowers;
  final Map<String, SkyPosition> meteorShowerPositions;
  final List<SkyPosition> milkyWayPlanePositions;
  final SkyProjection projection;
  final StarRenderingStyle style;
  final String? selectedStarId;
  final Function(Map<String, Offset> renderedStarOffsets)? onRenderedPositions;
  final List<Rect> _labelRects = [];
  Size _paintSize = Size.zero;

  StarMapPainter({
    required this.stars,
    required this.starPositions,
    this.planets = const [],
    this.planetPositions = const {},
    this.planetImages,
    required this.constellations,
    this.constellationPositions = const {},
    this.constellationBoundaryPositions = const [],
    this.constellationImages,
    this.deepSkyObjects = const [],
    this.deepSkyPositions = const {},
    this.asterisms = const [],
    this.activeMeteorShowers = const [],
    this.meteorShowerPositions = const {},
    this.milkyWayPlanePositions = const [],
    required this.projection,
    required this.style,
    this.selectedStarId,
    this.onRenderedPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintSize = size;
    _labelRects.clear();
    final rect = Offset.zero & size;

    // 1. Draw atmospheric background gradient
    _drawBackground(canvas, rect);

    _drawMilkyWayPlane(canvas);

    // 2. Draw celestial horizontal grid (altitude rings and azimuth lines)
    if (style.showCelestialGrid) {
      _drawCelestialGrid(canvas, size);
    }

    // 3. Draw horizon and cardinal directions
    if (style.showHorizon) {
      _drawHorizonAndCardinals(canvas, size);
    }

    if (style.showConstellationLines &&
        constellationBoundaryPositions.isNotEmpty) {
      _drawConstellationBoundaries(canvas);
    }

    // Map to collect screen coordinates of rendered objects (for hit-testing / taps)
    final Map<String, Offset> renderedOffsets = {};

    // 3.5. Draw glowing celestial constellation artwork figures
    if (style.showConstellationArt &&
        (projection.fieldOfView <= 50.0 || selectedStarId != null) &&
        constellationImages != null &&
        constellationImages!.isNotEmpty) {
      _drawConstellationArtwork(canvas, renderedOffsets);
    }

    // 4. Draw constellation lines
    if (style.showConstellationLines) {
      _drawConstellations(canvas, renderedOffsets);
    }

    _drawAsterisms(canvas);

    // 5. Draw stars and glows
    _drawStars(canvas, renderedOffsets);

    // 6. Draw every Solar System body inside the current view.
    _drawPlanets(canvas, renderedOffsets);

    _drawDeepSkyObjects(canvas, renderedOffsets);
    _drawMeteorShowers(canvas, renderedOffsets);

    // 7. Draw constellation names
    if (style.showConstellationNames) {
      _drawConstellationNames(canvas, renderedOffsets);
    }

    // 8. Draw selection reticle
    if (selectedStarId != null) {
      _drawSelectionReticle(canvas, renderedOffsets);
    }

    // Report object screen offsets for hit testing
    if (onRenderedPositions != null) {
      onRenderedPositions!(renderedOffsets);
    }
  }

  void _drawBackground(Canvas canvas, Rect rect) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [style.skyZenithColor, style.skyHorizonColor, style.groundColor],
      stops: const [0.0, 0.65, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawCelestialGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = style.gridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Altitude rings at 30° and 60°
    for (final alt in [30.0, 60.0]) {
      final path = Path();
      bool firstPoint = true;
      for (double az = 0.0; az <= 360.0; az += 5.0) {
        final pt = projection.projectCoordinates(az, alt);
        if (pt != null) {
          if (firstPoint) {
            path.moveTo(pt.dx, pt.dy);
            firstPoint = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          firstPoint = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Azimuth lines every 45°
    for (double az = 0.0; az < 360.0; az += 45.0) {
      final path = Path();
      bool firstPoint = true;
      for (double alt = -10.0; alt <= 85.0; alt += 5.0) {
        final pt = projection.projectCoordinates(az, alt);
        if (pt != null) {
          if (firstPoint) {
            path.moveTo(pt.dx, pt.dy);
            firstPoint = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          firstPoint = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawHorizonAndCardinals(Canvas canvas, Size size) {
    final horizonPaint = Paint()
      ..color = style.horizonLineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final horizonPath = Path();
    bool first = true;
    for (double az = 0.0; az <= 360.0; az += 3.0) {
      final pt = projection.projectCoordinates(az, 0.0);
      if (pt != null) {
        if (first) {
          horizonPath.moveTo(pt.dx, pt.dy);
          first = false;
        } else {
          horizonPath.lineTo(pt.dx, pt.dy);
        }
      } else {
        first = true;
      }
    }
    canvas.drawPath(horizonPath, horizonPaint);

    // Cardinal directions
    const cardinals = [
      (az: 0.0, label: 'N'),
      (az: 45.0, label: 'NE'),
      (az: 90.0, label: 'E'),
      (az: 135.0, label: 'SE'),
      (az: 180.0, label: 'S'),
      (az: 225.0, label: 'SW'),
      (az: 270.0, label: 'W'),
      (az: 315.0, label: 'NW'),
    ];

    for (final c in cardinals) {
      final pt = projection.projectCoordinates(c.az, 0.0);
      if (pt != null &&
          pt.dx >= -20 &&
          pt.dx <= size.width + 20 &&
          pt.dy >= -20 &&
          pt.dy <= size.height + 20) {
        final tp = TextPainter(
          text: TextSpan(
            text: c.label,
            style: TextStyle(
              color: style.cardinalColor,
              fontSize: c.label.length == 1 ? 14.0 : 11.0,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4.0)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final topLeft = pt - Offset(tp.width / 2.0, tp.height + 4.0);
        final labelRect = topLeft & tp.size;
        if (!_labelRects.any((rect) => rect.overlaps(labelRect))) {
          _labelRects.add(labelRect);
          tp.paint(canvas, topLeft);
        }
      }
    }
  }

  double get _starMagnitudeLimit {
    final fovLimit = projection.fieldOfView > 95
        ? 1.5
        : (projection.fieldOfView > 75
              ? 2.5
              : (projection.fieldOfView > 50 ? 4.0 : style.limitingMagnitude));
    return math.min(style.limitingMagnitude, fovLimit);
  }

  bool _isMainConstellation(Constellation constellation) {
    const mainIds = {
      'ori',
      'uma',
      'umi',
      'cas',
      'sco',
      'leo',
      'tau',
      'cyg',
      'gem',
      'and',
      'sgr',
      'vir',
      'cru',
      'cen',
      'peg',
      'lyr',
      'aql',
      'her',
      'per',
      'cma',
      'cmi',
      'oph',
    };
    return mainIds.contains(constellation.id.toLowerCase());
  }

  bool _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle textStyle, {
    bool centered = false,
    bool force = false,
  }) {
    if (text.isEmpty) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: _paintSize.width * 0.75);
    final w = painter.width;
    final h = painter.height;
    final candidates = centered
        ? [
            anchor - Offset(w / 2, h / 2),
            anchor + Offset(8, -h / 2),
            anchor - Offset(w + 8, h / 2),
            anchor + Offset(-w / 2, -h - 6),
            anchor + Offset(-w / 2, 6),
          ]
        : [
            anchor + Offset(8, -h / 2),
            anchor - Offset(w + 8, h / 2),
            anchor + Offset(-w / 2, -h - 7),
            anchor + Offset(-w / 2, 7),
          ];

    Rect? chosen;
    for (final topLeft in candidates) {
      final rect = topLeft & Size(w, h);
      if (rect.left < 2 ||
          rect.top < 2 ||
          rect.right > _paintSize.width - 2 ||
          rect.bottom > _paintSize.height - 2) {
        continue;
      }
      if (_labelRects.any((existing) => existing.overlaps(rect))) continue;
      chosen = rect;
      break;
    }
    if (chosen == null && force && candidates.isNotEmpty) {
      chosen = candidates.first & Size(w, h);
    }
    if (chosen == null) return false;
    _labelRects.add(chosen);
    painter.paint(canvas, chosen.topLeft);
    return true;
  }

  void _drawMilkyWayPlane(Canvas canvas) {
    if (milkyWayPlanePositions.length < 2 || projection.fieldOfView > 95) {
      return;
    }
    final paint = Paint()
      ..color = (style.nightMode
          ? const Color(0x26FF4444)
          : const Color(0x385A83A8))
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    final path = Path();
    bool drawing = false;
    for (final position in milkyWayPlanePositions) {
      final point = projection.projectSkyPosition(position);
      if (point == null) {
        drawing = false;
      } else if (!drawing) {
        path.moveTo(point.dx, point.dy);
        drawing = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawConstellationArtwork(
    Canvas canvas,
    Map<String, Offset> offsetCache,
  ) {
    if (constellationImages == null || constellationImages!.isEmpty) return;

    for (final con in constellations) {
      final pos = constellationPositions[con.id];
      if (pos == null) continue;

      final pt = projection.projectSkyPosition(pos);
      if (pt == null) continue;

      // Cache screen position for hit testing and selection reticle
      offsetCache[con.id] = pt;
      offsetCache[con.name.toLowerCase()] = pt;

      final key = con.id.toLowerCase();
      final isSelected =
          selectedStarId != null &&
          (selectedStarId!.toLowerCase() == con.id.toLowerCase() ||
              selectedStarId!.toLowerCase() == con.name.toLowerCase());

      if (!isSelected && projection.fieldOfView > 50.0) continue;

      // Only draw dedicated artwork for constellations that have it,
      // or default artwork if explicitly selected by the user.
      final img =
          constellationImages![key] ??
          (isSelected ? constellationImages!['default'] : null);
      if (img == null) continue;

      // Ethereal mythological glow opacity
      final alpha = isSelected ? 0.92 : (style.nightMode ? 0.35 : 0.65);

      final artSize =
          (projection.viewportSize.shortestSide *
                  0.48 *
                  (65.0 / projection.fieldOfView))
              .clamp(160.0, 480.0);

      // Ethereal backing nebula aura behind the mythological figure
      final auraPaint = Paint()
        ..color =
            (style.nightMode
                    ? const Color(0xFFFF2222)
                    : (isSelected
                          ? AstroTrackColors.accent
                          : const Color(0xFF589BFF)))
                .withValues(alpha: isSelected ? 0.28 : 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0);
      canvas.drawCircle(pt, artSize * 0.38, auraPaint);

      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);

      if (style.nightMode) {
        paint.colorFilter = const ColorFilter.mode(
          Color(0xFFFF3333),
          BlendMode.srcATop,
        );
      }

      final dst = Rect.fromCenter(center: pt, width: artSize, height: artSize);
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      canvas.drawImageRect(img, src, dst, paint);
    }
  }

  void _drawConstellations(Canvas canvas, Map<String, Offset> offsetCache) {
    final defaultLinePaint = Paint()
      ..color = style.constellationLineColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final selectedLinePaint = Paint()
      ..color = style.nightMode
          ? const Color(0xFFFF4444)
          : AstroTrackColors.accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (final con in constellations) {
      final isSelected =
          selectedStarId != null &&
          (selectedStarId!.toLowerCase() == con.id.toLowerCase() ||
              selectedStarId!.toLowerCase() == con.name.toLowerCase());
      if (projection.fieldOfView > 90.0 &&
          !_isMainConstellation(con) &&
          !isSelected) {
        continue;
      }
      final linePaint = isSelected ? selectedLinePaint : defaultLinePaint;

      for (final line in con.lines) {
        final pos1 = starPositions[line.starId1];
        final pos2 = starPositions[line.starId2];

        if (pos1 == null || pos2 == null) continue;

        final pt1 =
            offsetCache[line.starId1] ?? projection.projectSkyPosition(pos1);
        final pt2 =
            offsetCache[line.starId2] ?? projection.projectSkyPosition(pos2);

        if (pt1 != null && pt2 != null) {
          // Guard against wrapping glitches across projection boundary
          final distSq =
              (pt2.dx - pt1.dx) * (pt2.dx - pt1.dx) +
              (pt2.dy - pt1.dy) * (pt2.dy - pt1.dy);
          if (distSq < 150000) {
            canvas.drawLine(pt1, pt2, linePaint);
          }
        }
      }
    }
  }

  void _drawConstellationBoundaries(Canvas canvas) {
    final paint = Paint()
      ..color = style.nightMode
          ? const Color(0x42FF3333)
          : AstroTrackColors.secondary.withValues(alpha: 0.16)
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final boundary in constellationBoundaryPositions) {
      final path = Path();
      var drawing = false;
      for (final position in boundary) {
        final point = projection.projectSkyPosition(position);
        if (point == null) {
          drawing = false;
        } else if (!drawing) {
          path.moveTo(point.dx, point.dy);
          drawing = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawAsterisms(Canvas canvas) {
    if (projection.fieldOfView > 75.0) return;
    final linePaint = Paint()
      ..color = style.nightMode
          ? const Color(0x66FF6666)
          : const Color(0x9976B7FF)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    final labelStyle = TextStyle(
      color: style.nightMode
          ? const Color(0xFFFF7777)
          : const Color(0xFFD1E5FF),
      fontSize: 10.0,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
    );

    for (final asterism in asterisms) {
      final points = <String, Offset>{};
      for (final line in asterism.lines) {
        if (line.length < 2) continue;
        final firstPosition = starPositions[line[0]];
        final secondPosition = starPositions[line[1]];
        if (firstPosition == null || secondPosition == null) continue;
        final first = projection.projectSkyPosition(firstPosition);
        final second = projection.projectSkyPosition(secondPosition);
        if (first == null || second == null) continue;
        final distanceSquared =
            (first.dx - second.dx) * (first.dx - second.dx) +
            (first.dy - second.dy) * (first.dy - second.dy);
        if (distanceSquared > 150000) continue;
        canvas.drawLine(first, second, linePaint);
        points[line[0]] = first;
        points[line[1]] = second;
      }
      if (points.isEmpty) continue;
      final center =
          points.values.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
          points.length.toDouble();
      if (projection.fieldOfView <= 65.0) {
        _drawLabel(canvas, asterism.name, center, labelStyle, centered: true);
      }
    }
  }

  bool _isDeepSkyVisible(DeepSkyObject object, bool selected) {
    if (selected) return true;
    final fov = projection.fieldOfView;
    if (object.visibilityClass == 'marker') return fov <= 55.0;
    if (object.visibilityClass == 'feature') return fov <= 75.0;
    if (object.visibilityClass == 'telescopic') return fov <= 38.0;
    if (fov > 70.0) return false;

    final magnitude = object.apparentMagnitude;
    final sizeArcminutes = object.angularSizeMajorArcminutes ?? 0.0;
    final apparentFraction = sizeArcminutes / (60.0 * fov);
    if (fov > 48.0) {
      return magnitude == null
          ? apparentFraction >= 0.012
          : magnitude <= 6.5 || apparentFraction >= 0.02;
    }
    if (fov > 32.0) return magnitude == null || magnitude <= 9.0;
    return magnitude == null || magnitude <= 12.0;
  }

  void _drawDeepSkyObjects(Canvas canvas, Map<String, Offset> offsetCache) {
    final labelStyle = TextStyle(
      color: style.nightMode
          ? const Color(0xFFFF7777)
          : const Color(0xFFFFD180),
      fontSize: 10.0,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
    );
    for (final object in deepSkyObjects) {
      final selected = object.id == selectedStarId;
      if (!_isDeepSkyVisible(object, selected)) continue;
      final position = deepSkyPositions[object.id];
      if (position == null) continue;
      final point = projection.projectSkyPosition(position);
      if (point == null) continue;
      offsetCache[object.id] = point;

      final majorArcminutes = object.angularSizeMajorArcminutes ?? 12.0;
      final minorArcminutes =
          object.angularSizeMinorArcminutes ?? majorArcminutes;
      final isDarkNebula = object.objectType.toLowerCase().contains(
        'dark nebula',
      );
      final maxDiameter = isDarkNebula ? _paintSize.shortestSide * 0.62 : 38.0;
      final diameterX =
          (majorArcminutes /
                  (60.0 * projection.fieldOfView) *
                  projection.viewportSize.shortestSide)
              .clamp(5.0, maxDiameter);
      final diameterY =
          (minorArcminutes /
                  (60.0 * projection.fieldOfView) *
                  projection.viewportSize.shortestSide)
              .clamp(4.0, isDarkNebula ? maxDiameter : 30.0);
      final color = style.nightMode
          ? const Color(0xFFFF5555)
          : (selected
                ? AstroTrackColors.accent
                : (isDarkNebula
                      ? const Color(0xFF9EB0C1)
                      : const Color(0xFFFFCA80)));
      final marker = Rect.fromCenter(
        center: point,
        width: diameterX,
        height: diameterY,
      );
      canvas.drawOval(
        marker,
        Paint()
          ..color = isDarkNebula
              ? const Color(
                  0xFF090F16,
                ).withValues(alpha: selected ? 0.36 : 0.22)
              : color.withValues(alpha: selected ? 0.28 : 0.15),
      );
      canvas.drawOval(
        marker,
        Paint()
          ..color = color.withValues(alpha: selected ? 0.95 : 0.75)
          ..strokeWidth = selected ? 1.8 : 1.1
          ..style = PaintingStyle.stroke,
      );
      final labelEnabled =
          style.showStarLabels && (selected || projection.fieldOfView <= 55.0);
      if (labelEnabled) {
        final label = object.name;
        _drawLabel(
          canvas,
          label,
          point + Offset(diameterX / 2.0 + 3.0, 0),
          labelStyle,
          force: selected,
        );
      }
    }
  }

  void _drawMeteorShowers(Canvas canvas, Map<String, Offset> offsetCache) {
    if (projection.fieldOfView > 95.0) return;
    for (final shower in activeMeteorShowers) {
      final position = meteorShowerPositions[shower.id];
      if (position == null) continue;
      final point = projection.projectSkyPosition(position);
      if (point == null) continue;
      offsetCache['SHOWER:${shower.id}'] = point;
      final color = style.nightMode
          ? const Color(0xFFFF5555)
          : const Color(0xFF80DEEA);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        point + const Offset(-5, 0),
        point + const Offset(5, 0),
        paint,
      );
      canvas.drawLine(
        point + const Offset(0, -5),
        point + const Offset(0, 5),
        paint,
      );
      if (projection.fieldOfView <= 70.0 && style.showStarLabels) {
        _drawLabel(
          canvas,
          '${shower.name} radiant',
          point + const Offset(7, 0),
          TextStyle(
            color: color,
            fontSize: 9.5,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        );
      }
    }
  }

  void _drawStars(Canvas canvas, Map<String, Offset> offsetCache) {
    final textStyle = TextStyle(
      color: style.textColor,
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      shadows: const [Shadow(color: Colors.black, blurRadius: 3.0)],
    );

    for (final star in stars) {
      final isSelected = star.id == selectedStarId;

      // Declutter: hide the least famous stars unless explicitly selected by the user!
      // This keeps the sky clean while allowing any star to be discovered via search.
      if (style.hideLeastFamousStars &&
          projection.fieldOfView > 80.0 &&
          !star.isFamous &&
          !isSelected) {
        continue;
      }

      if (star.apparentMagnitude > _starMagnitudeLimit && !isSelected) {
        continue;
      }

      final pos = starPositions[star.id];
      if (pos == null) continue;

      final pt = offsetCache[star.id] ?? projection.projectSkyPosition(pos);
      if (pt == null) continue;

      offsetCache[star.id] = pt;

      final radius = style.getStarRadius(star.apparentMagnitude);
      final alpha = style.getStarAlpha(star.apparentMagnitude);
      final starColor = style.nightMode ? const Color(0xFFFF4444) : star.color;

      // Glow for bright stars (magnitude <= 2.0)
      if (star.apparentMagnitude <= 2.0) {
        final glowRadius = radius * (star.apparentMagnitude <= 0.0 ? 3.2 : 2.2);
        final glowPaint = Paint()
          ..color = starColor.withValues(alpha: alpha * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(pt, glowRadius, glowPaint);
      }

      // Star core
      final corePaint = Paint()
        ..color = starColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, radius, corePaint);

      // Star label: only show for iconic bright stars (magnitude <= 1.5) or explicitly selected star
      if (style.showStarLabels &&
          (star.apparentMagnitude <= 1.5 || isSelected) &&
          (projection.fieldOfView <= 85.0 || isSelected)) {
        final label = star.commonName ?? star.bayerDesignation ?? '';
        if (label.isNotEmpty) {
          _drawLabel(
            canvas,
            label,
            pt + Offset(radius + 3.0, 0),
            textStyle,
            force: isSelected,
          );
        }
      }
    }
  }

  void _drawPlanets(Canvas canvas, Map<String, Offset> offsetCache) {
    for (final planet in planets) {
      final isSelected = planet.id == selectedStarId;
      final isMinorBody =
          planet.type == PlanetType.asteroid ||
          planet.type == PlanetType.dwarfPlanet ||
          planet.type == PlanetType.comet;
      final pos = planetPositions[planet.id];
      if (pos == null) continue;

      final color = style.nightMode
          ? const Color(0xFFFF3333)
          : planet.baseColor;
      final pt = projection.projectSkyPosition(pos);
      if (pt == null ||
          pt.dx < 0.0 ||
          pt.dx > _paintSize.width ||
          pt.dy < 0.0 ||
          pt.dy > _paintSize.height) {
        continue;
      }

      offsetCache[planet.id] = pt;

      final img = planetImages?[planet.type];
      if (img != null) {
        // Render photorealistic 3D planet image instead of a dot!
        double renderSize;
        if (planet.isSun) {
          renderSize = 48.0;
        } else if (planet.type == PlanetType.saturn) {
          renderSize = 52.0; // wider to accommodate tilted rings!
        } else if (planet.type == PlanetType.jupiter) {
          renderSize = 36.0;
        } else if (planet.isMoon) {
          renderSize = 28.0;
        } else if (planet.type == PlanetType.venus) {
          renderSize = 26.0;
        } else if (planet.type == PlanetType.mars) {
          renderSize = 24.0;
        } else if (planet.type == PlanetType.mercury) {
          renderSize = 20.0;
        } else if (planet.type == PlanetType.pluto) {
          renderSize = 16.0;
        } else {
          renderSize = 26.0; // Uranus, Neptune
        }

        // Atmosphere halo glow behind planet
        final haloPaint = Paint()
          ..color =
              (style.nightMode
                      ? const Color(0xFFFF3333)
                      : (planet.isSun ? const Color(0xFFFFD700) : color))
                  .withValues(alpha: planet.isSun ? 0.45 : 0.28)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            planet.isSun ? 14.0 : 6.0,
          );
        canvas.drawCircle(pt, renderSize * 0.58, haloPaint);

        // Draw the textured 3D planet image
        final dstRect = Rect.fromCenter(
          center: pt,
          width: renderSize,
          height: renderSize,
        );
        final srcRect = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        final imgPaint = Paint();
        if (style.nightMode) {
          imgPaint.colorFilter = const ColorFilter.mode(
            Color(0xFFFF3333),
            BlendMode.srcATop,
          );
        }
        canvas.drawImageRect(img, srcRect, dstRect, imgPaint);
      } else if (planet.isSun) {
        // Fallback: Radiant golden corona & disk
        final coronaPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
        canvas.drawCircle(pt, 24.0, coronaPaint);

        final midGlow = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(pt, 16.0, midGlow);

        final corePaint = Paint()..color = color;
        canvas.drawCircle(pt, 11.0, corePaint);
      } else if (planet.isMoon) {
        // Fallback: Lunar disk with phase illumination
        final moonGlow = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(pt, 15.0, moonGlow);

        final darkPaint = Paint()..color = const Color(0xFF263238);
        canvas.drawCircle(pt, 10.0, darkPaint);

        final litPaint = Paint()..color = color;
        if (planet.illuminatedFraction > 0.8) {
          canvas.drawCircle(pt, 10.0, litPaint);
        } else {
          final crescentPath = Path()
            ..addArc(
              Rect.fromCircle(center: pt, radius: 10.0),
              -math.pi / 2,
              math.pi,
            )
            ..lineTo(pt.dx, pt.dy - 10.0);
          canvas.drawPath(crescentPath, litPaint);
        }
      } else if (planet.type == PlanetType.saturn) {
        // Fallback Saturn: Disk with dual ring system
        final ringGlow = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(pt, 14.0, ringGlow);

        final ringPaint = Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        final innerRingPaint = Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.save();
        canvas.translate(pt.dx, pt.dy);
        canvas.rotate(0.35);
        canvas.drawOval(const Rect.fromLTWH(-16, -5, 32, 10), ringPaint);
        canvas.drawOval(const Rect.fromLTWH(-12, -3.5, 24, 7), innerRingPaint);
        canvas.restore();

        final saturnPaint = Paint()..color = color;
        canvas.drawCircle(pt, 6.5, saturnPaint);
      } else if (planet.type == PlanetType.jupiter) {
        final outerAura = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
        canvas.drawCircle(pt, 16.0, outerAura);

        final midGlow = Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pt, 11.0, midGlow);

        final corePaint = Paint()..color = color;
        canvas.drawCircle(pt, 8.0, corePaint);

        final bandPaint = Paint()
          ..color = const Color(0xFFD78B45).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawLine(
          pt + const Offset(-6.2, -1.8),
          pt + const Offset(6.2, -1.8),
          bandPaint,
        );
        canvas.drawLine(
          pt + const Offset(-6.2, 1.8),
          pt + const Offset(6.2, 1.8),
          bandPaint,
        );
      } else if (planet.type == PlanetType.pluto) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(pt, 5.0, glowPaint);

        final corePaint = Paint()..color = color;
        canvas.drawCircle(pt, 3.5, corePaint);
      } else {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pt, 9.0, glowPaint);

        final corePaint = Paint()..color = color;
        canvas.drawCircle(pt, 5.5, corePaint);
      }

      // Planet label: Symbol + Name
      final labelVisible = planet.isGalileanMoon
          ? projection.fieldOfView <= 27.0 || isSelected
          : (isMinorBody ? projection.fieldOfView <= 40.0 || isSelected : true);
      if ((style.showStarLabels && labelVisible) || isSelected) {
        final labelText =
            '${planet.symbol} ${planet.name}'
            '${pos.altitude < 0 ? ' (below horizon)' : ''}';
        _drawLabel(
          canvas,
          labelText,
          pt + const Offset(11.0, -5.0),
          TextStyle(
            color: style.nightMode
                ? Colors.redAccent
                : (pos.altitude < 0 ? color.withValues(alpha: 0.65) : color),
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4.0)],
          ),
          force: isSelected,
        );
      }
    }
  }

  void _drawConstellationNames(Canvas canvas, Map<String, Offset> offsetCache) {
    final conTextStyle = TextStyle(
      color: style.secondaryTextColor,
      fontSize: 11.0,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black, blurRadius: 4.0)],
    );

    for (final con in constellations) {
      final isSelected =
          selectedStarId != null &&
          (selectedStarId!.toLowerCase() == con.id.toLowerCase() ||
              selectedStarId!.toLowerCase() == con.name.toLowerCase());
      if (projection.fieldOfView > 75.0 &&
          !_isMainConstellation(con) &&
          !isSelected) {
        continue;
      }
      final pos = constellationPositions[con.id];
      final pt = pos != null ? projection.projectSkyPosition(pos) : null;
      if (pt != null) {
        offsetCache[con.id] = pt;
        offsetCache[con.name.toLowerCase()] = pt;

        final styleToUse = isSelected
            ? conTextStyle.copyWith(
                color: style.selectionColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                shadows: [
                  Shadow(
                    color: style.selectionColor.withValues(alpha: 0.8),
                    blurRadius: 8.0,
                  ),
                  const Shadow(color: Colors.black, blurRadius: 4.0),
                ],
              )
            : conTextStyle;

        _drawLabel(
          canvas,
          con.name.toUpperCase(),
          pt,
          styleToUse,
          centered: true,
          force: isSelected,
        );
      }
    }
  }

  void _drawSelectionReticle(Canvas canvas, Map<String, Offset> offsetCache) {
    final pt = offsetCache[selectedStarId];
    if (pt == null) return;

    final reticlePaint = Paint()
      ..color = style.selectionColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const ringRadius = 18.0;
    // Draw target ring
    canvas.drawCircle(pt, ringRadius, reticlePaint);

    // Draw 4 corner reticle ticks
    const tickLen = 6.0;
    canvas.drawLine(
      pt + const Offset(-ringRadius - tickLen, 0),
      pt + const Offset(-ringRadius, 0),
      reticlePaint,
    );
    canvas.drawLine(
      pt + const Offset(ringRadius, 0),
      pt + const Offset(ringRadius + tickLen, 0),
      reticlePaint,
    );
    canvas.drawLine(
      pt + const Offset(0, -ringRadius - tickLen),
      pt + const Offset(0, -ringRadius),
      reticlePaint,
    );
    canvas.drawLine(
      pt + const Offset(0, ringRadius),
      pt + const Offset(0, ringRadius + tickLen),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant StarMapPainter oldDelegate) {
    return oldDelegate.projection != projection ||
        oldDelegate.style != style ||
        oldDelegate.selectedStarId != selectedStarId ||
        oldDelegate.starPositions != starPositions ||
        oldDelegate.planets != planets ||
        oldDelegate.planetPositions != planetPositions ||
        oldDelegate.constellationPositions != constellationPositions ||
        oldDelegate.constellationBoundaryPositions !=
            constellationBoundaryPositions ||
        oldDelegate.deepSkyObjects != deepSkyObjects ||
        oldDelegate.deepSkyPositions != deepSkyPositions ||
        oldDelegate.asterisms != asterisms ||
        oldDelegate.activeMeteorShowers != activeMeteorShowers ||
        oldDelegate.meteorShowerPositions != meteorShowerPositions ||
        oldDelegate.milkyWayPlanePositions != milkyWayPlanePositions;
  }
}
