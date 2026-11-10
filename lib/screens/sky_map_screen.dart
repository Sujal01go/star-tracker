import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/asterism_catalogue.dart';
import '../data/constellation_repository.dart';
import '../data/deep_sky_catalogue_repository.dart';
import '../data/meteor_shower_catalogue.dart';
import '../data/star_catalogue_repository.dart';
import '../models/constellation.dart';
import '../models/deep_sky_object.dart';
import '../models/meteor_shower.dart';
import '../models/observation_time.dart';
import '../models/observer_location.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import '../rendering/sky_projection.dart';
import '../rendering/star_map_painter.dart';
import '../rendering/star_rendering_style.dart';
import '../sensors/device_orientation_service.dart';
import '../services/constellation_asset_service.dart';
import '../services/jpl_horizons_service.dart';
import '../services/location_service.dart';
import '../services/planet_data_service.dart';
import '../services/preferences_service.dart';
import '../widgets/location_indicator.dart';
import '../widgets/orientation_indicator.dart';
import '../widgets/sky_map_controls.dart';
import '../widgets/star_information_card.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'star_details_screen.dart';
import 'time_selection_screen.dart';

/// Primary interactive star-tracking canvas screen.
class SkyMapScreen extends StatefulWidget {
  final StarCatalogueRepository starRepository;
  final ConstellationRepository constellationRepository;
  final AstronomyEngine astronomyEngine;
  final DeviceOrientationService orientationService;
  final PreferencesService? preferencesService;

  const SkyMapScreen({
    super.key,
    required this.starRepository,
    required this.constellationRepository,
    required this.astronomyEngine,
    required this.orientationService,
    this.preferencesService,
  });

  @override
  State<SkyMapScreen> createState() => SkyMapScreenState();
}

class SkyMapScreenState extends State<SkyMapScreen>
    with SingleTickerProviderStateMixin {
  // Rendering & Camera parameters
  double _fieldOfView = 65.0; // degrees
  double _previousScaleFov = 65.0;
  double _previousGestureScale = 1.0;
  int _lastGesturePointerCount = 1;
  Offset? _lastPanFocalPoint;
  Size _gestureViewportSize = Size.zero;
  bool _gestureHadMultiplePointers = false;
  late final Ticker _inertiaTicker;
  Offset _inertiaVelocity = Offset.zero;
  Duration? _lastInertiaTick;

  // Visual style state
  late StarRenderingStyle _style;

  // Selected star or planet state
  String? _selectedStarId;
  final DeepSkyCatalogueRepository _deepSkyRepository =
      DeepSkyCatalogueRepository();
  final JplHorizonsService _jplHorizonsService = JplHorizonsService();
  DateTime? _lastHorizonsAttemptAt;
  DateTime? _lastHorizonsObservationTime;
  bool _horizonsRequestInProgress = false;
  Timer? _horizonsRefreshTimer;
  Map<String, Offset> _renderedStarOffsets = {};

  // Cached calculated sky positions
  Map<String, SkyPosition> _computedPositions = {};
  Map<String, SkyPosition> _computedConstellationPositions = {};
  List<List<SkyPosition>> _computedConstellationBoundaryPositions = [];
  Map<String, SkyPosition> _computedDeepSkyPositions = {};
  Map<String, SkyPosition> _computedMeteorPositions = {};
  List<MeteorShower> _activeMeteorShowers = [];
  List<SkyPosition> _computedMilkyWayPlane = [];

  // Timers
  Timer? _realTimeClockTimer;
  bool _mapAssetsReady = false;

  @override
  void initState() {
    super.initState();
    _inertiaTicker = createTicker(_stepInertia);
    _style =
        widget.preferencesService?.loadRenderingStyle() ??
        const StarRenderingStyle();

    // Start hardware sensors
    widget.orientationService.start();
    widget.orientationService.setTracking(true);
    widget.orientationService.addListener(_onOrientationUpdated);
    widget.astronomyEngine.addListener(_onAstronomyUpdated);

    // Initial astronomical computation
    _recomputeSkyPositions();
    _refreshHorizonsCoordinatesIfNeeded();

    // Setup 1-second real-time observation clock
    _realTimeClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.astronomyEngine.time.isRealTime && mounted) {
        widget.astronomyEngine.updateTime(ObservationTime.now());
      }
    });

    // Load catalogues and image assets together so the map switches from its
    // vector fallbacks to the complete sprite set in one frame.
    _prepareSkyMap();

    // Auto-acquire device GPS fix if location is still default Greenwich
    _initGpsLocation();
  }

  Future<void> _initGpsLocation() async {
    if (widget.astronomyEngine.location == ObserverLocation.greenwich) {
      final result = await LocationService.getCurrentGpsLocation();
      if (result.isSuccess && mounted) {
        widget.astronomyEngine.updateLocation(result.location!);
        widget.preferencesService?.saveLocation(result.location!);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set observer location to ${result.location!.name}'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLocationSelectionSheet() {
    final isNight = _style.nightMode;
    final cardBg = isNight
        ? const Color(0xF0200505)
        : AstroTrackColors.surface.withValues(alpha: 0.97);
    final borderColor = isNight
        ? const Color(0x66FF3333)
        : AstroTrackColors.line;
    final textPrimary = _style.textColor;
    final textSecondary = _style.secondaryTextColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(12.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Observer Location',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: textSecondary,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Accurate star positions depend directly on your observer latitude and longitude.',
                style: TextStyle(color: textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text(
                  'Use Current GPS Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final result = await LocationService.getCurrentGpsLocation();
                  if (result.isSuccess && mounted) {
                    widget.astronomyEngine.updateLocation(result.location!);
                    widget.preferencesService?.saveLocation(result.location!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated to ${result.location!.name}'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.errorMessage ?? 'GPS unavailable'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              Text(
                'QUICK PRESETS',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              ...[
                ObserverLocation.newDelhi,
                ObserverLocation.tokyo,
                ObserverLocation.newYork,
                ObserverLocation.sydney,
                ObserverLocation.greenwich,
              ].map((loc) {
                final isCurrent =
                    widget.astronomyEngine.location.name == loc.name;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isCurrent ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isCurrent ? accent : textSecondary,
                  ),
                  title: Text(
                    loc.name,
                    style: TextStyle(
                      color: isCurrent ? accent : textPrimary,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13.0,
                    ),
                  ),
                  subtitle: Text(
                    '${loc.latitude >= 0 ? "${loc.latitude}°N" : "${-loc.latitude}°S"}, ${loc.longitude >= 0 ? "${loc.longitude}°E" : "${-loc.longitude}°W"}',
                    style: TextStyle(color: textSecondary, fontSize: 11.0),
                  ),
                  onTap: () {
                    widget.astronomyEngine.updateLocation(loc);
                    widget.preferencesService?.saveLocation(loc);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCatalogues() async {
    final loads = <Future<void>>[];
    if (!widget.starRepository.isLoaded) {
      loads.add(widget.starRepository.loadCatalogue());
    }
    if (!widget.constellationRepository.isLoaded) {
      loads.add(widget.constellationRepository.loadConstellations());
    }
    loads.add(_deepSkyRepository.loadCatalogue());
    await Future.wait(loads);
    if (mounted) _recomputeSkyPositions();
  }

  Future<void> _prepareSkyMap() async {
    await Future.wait([
      _loadCatalogues(),
      PlanetDataService.preloadUiImages(),
      ConstellationAssetService.preloadUiImages(),
    ]);
    if (mounted) setState(() => _mapAssetsReady = true);
  }

  void _onOrientationUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAstronomyUpdated() {
    if (mounted) {
      _recomputeSkyPositions();
      _refreshHorizonsCoordinatesIfNeeded();
    }
  }

  void _refreshHorizonsCoordinatesIfNeeded() {
    // JPL does not currently allow browser cross-origin requests. The local
    // ephemeris remains active on web and whenever the network is unavailable.
    if (kIsWeb || !mounted || _horizonsRequestInProgress) return;

    final now = DateTime.now().toUtc();
    final observationTime = widget.astronomyEngine.time.utcDateTime;
    final manualTimeChanged =
        !widget.astronomyEngine.time.isRealTime &&
        _lastHorizonsObservationTime != null &&
        observationTime.difference(_lastHorizonsObservationTime!).abs() >
            const Duration(minutes: 1);
    final lastAttemptAt = _lastHorizonsAttemptAt;
    final periodicRefreshDue =
        lastAttemptAt == null ||
        now.difference(lastAttemptAt) >= const Duration(minutes: 10);
    if (manualTimeChanged &&
        !periodicRefreshDue &&
        now.difference(lastAttemptAt) < const Duration(minutes: 2)) {
      _horizonsRefreshTimer?.cancel();
      final remaining =
          const Duration(minutes: 2) - now.difference(lastAttemptAt);
      _horizonsRefreshTimer = Timer(remaining, () {
        if (mounted) _refreshHorizonsCoordinatesIfNeeded();
      });
      return;
    }
    final refreshDue = periodicRefreshDue || manualTimeChanged;
    if (!refreshDue) return;

    _lastHorizonsAttemptAt = now;
    _lastHorizonsObservationTime = observationTime;
    _horizonsRequestInProgress = true;

    _jplHorizonsService
        .fetchSolarSystemCoordinates(
          observationTime,
          allowRecentCache: widget.astronomyEngine.time.isRealTime,
        )
        .then((snapshot) {
          if (!mounted || snapshot.coordinates.isEmpty) return;
          final currentTime = widget.astronomyEngine.time.utcDateTime;
          if (currentTime.difference(observationTime).abs() >
              const Duration(minutes: 2)) {
            return;
          }
          widget.astronomyEngine.applyHorizonsCoordinates(
            snapshot.coordinates,
            observationTime: snapshot.observationTime,
          );
        })
        .catchError((Object error) {
          debugPrint('JPL Horizons update unavailable: $error');
        })
        .whenComplete(() {
          _horizonsRequestInProgress = false;
          if (mounted) _refreshHorizonsCoordinatesIfNeeded();
        });
  }

  void _recomputeSkyPositions() {
    _computedPositions = widget.astronomyEngine.computeBatch(
      widget.starRepository.allStars,
    );
    _computedConstellationPositions = widget.astronomyEngine
        .computeConstellationPositions(
          widget.constellationRepository.allConstellations,
        );
    _computedConstellationBoundaryPositions = widget.astronomyEngine
        .computeConstellationBoundaryPositions(
          widget.constellationRepository.boundaries,
        );
    _computedDeepSkyPositions = {
      for (final object in _deepSkyRepository.allObjects)
        object.id: widget.astronomyEngine.computeFixedPosition(
          object.rightAscension,
          object.declination,
          coordinateEpoch: object.coordinateEpoch,
        ),
    };
    final now = widget.astronomyEngine.time.utcDateTime;
    _activeMeteorShowers = meteorShowers
        .where((shower) => shower.isActive(now))
        .toList(growable: false);
    _computedMeteorPositions = {
      for (final shower in _activeMeteorShowers)
        shower.id: widget.astronomyEngine.computeFixedPosition(
          shower.radiantRa,
          shower.radiantDec,
        ),
    };
    _computedMilkyWayPlane = widget.astronomyEngine
        .computeGalacticPlanePositions();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _realTimeClockTimer?.cancel();
    _horizonsRefreshTimer?.cancel();
    _inertiaTicker.dispose();
    widget.orientationService.removeListener(_onOrientationUpdated);
    widget.astronomyEngine.removeListener(_onAstronomyUpdated);
    super.dispose();
  }

  // Touch Gesture Handling
  void _onScaleStart(ScaleStartDetails details, Size viewportSize) {
    _stopInertia();
    _gestureViewportSize = viewportSize;
    _lastPanFocalPoint = details.localFocalPoint;
    _previousScaleFov = _fieldOfView;
    _previousGestureScale = 1.0;
    _lastGesturePointerCount = details.pointerCount;
    _gestureHadMultiplePointers = details.pointerCount >= 2;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount != _lastGesturePointerCount) {
      // Re-anchor when a second finger is added or removed so the camera does
      // not jump between one-finger rotation and two-finger zoom.
      _lastGesturePointerCount = details.pointerCount;
      _lastPanFocalPoint = details.localFocalPoint;
      _previousScaleFov = _fieldOfView;
      _previousGestureScale = details.scale;
      _gestureHadMultiplePointers =
          _gestureHadMultiplePointers || details.pointerCount >= 2;
      return;
    }

    if (details.pointerCount >= 2) {
      _gestureHadMultiplePointers = true;
      // 2-finger pinch zoom
      _lastPanFocalPoint = details.localFocalPoint;
      final scaleSinceAnchor = details.scale / _previousGestureScale;
      final newFov = (_previousScaleFov / scaleSinceAnchor).clamp(25.0, 110.0);
      setState(() {
        _fieldOfView = newFov;
      });
    } else if (details.pointerCount == 1 && _lastPanFocalPoint != null) {
      // Rotate the perspective camera like a trackball, keeping the patch of
      // sky under the finger attached to it throughout the drag.
      final previousPoint = _lastPanFocalPoint!;
      final currentPoint = details.localFocalPoint;
      _lastPanFocalPoint = currentPoint;

      final projection = SkyProjection(
        centerAzimuth: widget.orientationService.azimuth,
        centerAltitude: widget.orientationService.altitude,
        rollAngle: widget.orientationService.roll,
        fieldOfView: _fieldOfView,
        viewportSize: _gestureViewportSize,
      );
      final pose = projection.panByScreenDrag(previousPoint, currentPoint);
      if (pose != null) {
        widget.orientationService.setManualViewPose(
          azimuth: pose.azimuth,
          altitude: pose.altitude,
          roll: pose.roll,
        );
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_gestureHadMultiplePointers) return;

    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    if (speed < 100.0) return;

    final cappedSpeed = math.min(speed, 1400.0);
    _inertiaVelocity = velocity * (cappedSpeed / speed);
    _lastInertiaTick = null;
    _inertiaTicker.start();
  }

  void _stepInertia(Duration elapsed) {
    final previousTick = _lastInertiaTick;
    _lastInertiaTick = elapsed;
    if (previousTick == null || _gestureViewportSize.isEmpty) return;

    final deltaSeconds = ((elapsed - previousTick).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.05)
        .toDouble();
    if (deltaSeconds <= 0.0) return;

    final center = Offset(
      _gestureViewportSize.width / 2.0,
      _gestureViewportSize.height / 2.0,
    );
    var displacement = _inertiaVelocity * deltaSeconds;
    if (displacement.distance > 40.0) {
      displacement = displacement * (40.0 / displacement.distance);
    }
    final projection = SkyProjection(
      centerAzimuth: widget.orientationService.azimuth,
      centerAltitude: widget.orientationService.altitude,
      rollAngle: widget.orientationService.roll,
      fieldOfView: _fieldOfView,
      viewportSize: _gestureViewportSize,
    );
    final pose = projection.panByScreenDrag(center, center + displacement);
    if (pose != null) {
      widget.orientationService.setManualViewPose(
        azimuth: pose.azimuth,
        altitude: pose.altitude,
        roll: pose.roll,
      );
    }

    _inertiaVelocity = _inertiaVelocity * math.exp(-deltaSeconds / 0.38);
    if (_inertiaVelocity.distance < 16.0) _stopInertia();
  }

  void _stopInertia() {
    if (_inertiaTicker.isActive) _inertiaTicker.stop();
    _inertiaVelocity = Offset.zero;
    _lastInertiaTick = null;
  }

  void _onTapUp(TapUpDetails details) {
    final tapPos = details.localPosition;
    const hitRadius = 28.0;

    String? hitId;
    double closestDistSq = hitRadius * hitRadius;

    // First check exact star or planet hits
    for (final entry in _renderedStarOffsets.entries) {
      final isCon =
          widget.constellationRepository.getConstellationById(entry.key) !=
          null;
      if (isCon) continue;

      final starPos = entry.value;
      final dx = starPos.dx - tapPos.dx;
      final dy = starPos.dy - tapPos.dy;
      final distSq = dx * dx + dy * dy;

      if (distSq <= closestDistSq) {
        closestDistSq = distSq;
        hitId = entry.key;
      }
    }

    // If no star or planet was tapped, check constellation artwork centers
    if (hitId == null) {
      const conHitRadius = 75.0;
      double closestConDistSq = conHitRadius * conHitRadius;
      for (final entry in _renderedStarOffsets.entries) {
        final isCon =
            widget.constellationRepository.getConstellationById(entry.key) !=
            null;
        if (!isCon) continue;

        final pos = entry.value;
        final dx = pos.dx - tapPos.dx;
        final dy = pos.dy - tapPos.dy;
        final distSq = dx * dx + dy * dy;

        if (distSq <= closestConDistSq) {
          closestConDistSq = distSq;
          hitId = entry.key;
        }
      }
    }

    setState(() {
      _selectedStarId = hitId;
    });
  }

  void _centerOnStar(Star star) {
    final pos = _computedPositions[star.id];
    if (pos != null) {
      widget.orientationService.lookAt(
        azimuth: pos.azimuth,
        altitude: pos.altitude,
      );
    }
  }

  void centerOnStar(Star star) => _centerOnStar(star);

  void _centerOnDeepSkyObject(DeepSkyObject object) {
    final pos = _computedDeepSkyPositions[object.id];
    if (pos == null) return;
    setState(() => _selectedStarId = object.id);
    widget.orientationService.lookAt(
      azimuth: pos.azimuth,
      altitude: pos.altitude,
    );
  }

  void centerOnDeepSkyObject(DeepSkyObject object) =>
      _centerOnDeepSkyObject(object);

  void _showDeepSkyDetails(DeepSkyObject object) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _style.nightMode
            ? const Color(0xFF1E0505)
            : AstroTrackColors.surface,
        title: Text(object.name, style: TextStyle(color: _style.textColor)),
        content: SingleChildScrollView(
          child: Text(
            '${object.objectType}\n${object.catalogueName}'
            '${object.aliases.isEmpty ? '' : '\n${object.aliases.join(', ')}'}'
            '\n\n${object.description}'
            '\n\nCoordinates: J${object.coordinateEpoch.toStringAsFixed(0)}'
            '\nSource: ${object.source}',
            style: TextStyle(color: _style.secondaryTextColor, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: _style.textColor)),
          ),
        ],
      ),
    );
  }

  void centerOnPlanet(Planet planet) => _centerOnPlanet(planet);

  void centerOnConstellation(Constellation constellation) =>
      _centerOnConstellation(constellation);

  void centerOnConstellationById(String id) {
    final con = widget.constellationRepository.getConstellationById(id);
    if (con != null) {
      _centerOnConstellation(con);
    }
  }

  void _centerOnPlanet(Planet planet) {
    final pos = widget.astronomyEngine.solarSystemPositions[planet.id];
    if (pos != null) {
      widget.orientationService.lookAt(
        azimuth: pos.azimuth,
        altitude: pos.altitude,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pos.isVisible
                ? 'Centered on ${planet.symbol} ${planet.name} (Altitude ${pos.altitude.toStringAsFixed(1)}°)'
                : 'Centered on ${planet.symbol} ${planet.name} (Currently below horizon, Alt ${pos.altitude.toStringAsFixed(1)}°)',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: pos.isVisible
              ? AstroTrackColors.accentStrong
              : const Color(0xFF493D24),
        ),
      );
    }
  }

  void _centerOnConstellation(Constellation constellation) {
    setState(() {
      _selectedStarId = constellation.id;
    });
    final pos = widget.astronomyEngine.equatorialToHorizontal(
      constellation.centerRa,
      constellation.centerDec,
    );
    widget.orientationService.lookAt(
      azimuth: pos.azimuth,
      altitude: pos.altitude,
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pos.isVisible
              ? 'Centered on ${constellation.name} (${constellation.englishName})'
              : 'Centered on ${constellation.name} (Currently below horizon, Alt ${pos.altitude.toStringAsFixed(1)}°)',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: pos.isVisible
            ? AstroTrackColors.accentStrong
            : const Color(0xFF493D24),
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _fieldOfView = (_fieldOfView - 10.0).clamp(25.0, 110.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _fieldOfView = (_fieldOfView + 10.0).clamp(25.0, 110.0);
    });
  }

  Future<void> _openSearch() async {
    final SearchResult? selected = await Navigator.of(context)
        .push<SearchResult>(
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              repository: widget.starRepository,
              constellationRepository: widget.constellationRepository,
              astronomyEngine: widget.astronomyEngine,
              style: _style,
              deepSkyRepository: _deepSkyRepository,
            ),
          ),
        );

    if (selected != null && mounted) {
      if (selected.star != null) {
        setState(() {
          _selectedStarId = selected.star!.id;
        });
        _centerOnStar(selected.star!);
      } else if (selected.planet != null) {
        setState(() {
          _selectedStarId = selected.planet!.id;
        });
        _centerOnPlanet(selected.planet!);
      } else if (selected.constellation != null) {
        _centerOnConstellation(selected.constellation!);
      } else if (selected.deepSkyObject != null) {
        _centerOnDeepSkyObject(selected.deepSkyObject!);
      }
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          astronomyEngine: widget.astronomyEngine,
          orientationService: widget.orientationService,
          style: _style,
          preferencesService: widget.preferencesService,
          onStyleChanged: (newStyle) {
            setState(() {
              _style = newStyle;
            });
          },
        ),
      ),
    );
  }

  void _showHeadingCalibrationSheet() {
    final isNight = _style.nightMode;
    final cardBg = isNight
        ? const Color(0xF0200505)
        : AstroTrackColors.surface.withValues(alpha: 0.97);
    final borderColor = isNight
        ? const Color(0x66FF3333)
        : AstroTrackColors.line;
    final textPrimary = _style.textColor;
    final textSecondary = _style.secondaryTextColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final offset =
                widget.orientationService.calibration.manualHeadingOffset;
            return Container(
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.explore, size: 20, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Compass Calibration',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: textSecondary,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Heading Offset: ${offset >= 0 ? "+" : ""}${offset.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: accent,
                      fontSize: 15.0,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If objects appear shifted to the left (anticlockwise), tap -1° or -5° to shift the map right into exact alignment.',
                    style: TextStyle(color: textSecondary, fontSize: 11.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _calibrationNudgeButton(
                        '-5°',
                        -5.0,
                        accent,
                        textPrimary,
                        setSheetState,
                      ),
                      _calibrationNudgeButton(
                        '-1°',
                        -1.0,
                        accent,
                        textPrimary,
                        setSheetState,
                      ),
                      _calibrationResetButton(
                        '0° Reset',
                        accent,
                        textPrimary,
                        setSheetState,
                      ),
                      _calibrationNudgeButton(
                        '+1°',
                        1.0,
                        accent,
                        textPrimary,
                        setSheetState,
                      ),
                      _calibrationNudgeButton(
                        '+5°',
                        5.0,
                        accent,
                        textPrimary,
                        setSheetState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: offset,
                    min: -180.0,
                    max: 180.0,
                    divisions: 720,
                    activeColor: accent,
                    onChanged: (v) {
                      setSheetState(() {
                        widget.orientationService.setManualCalibrationOffset(v);
                      });
                      widget.preferencesService?.saveHeadingOffset(v);
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Rotate phone in figure-8 to clear internal magnetometer bias.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _calibrationNudgeButton(
    String label,
    double delta,
    Color accent,
    Color textPrimary,
    StateSetter setSheetState,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        minimumSize: const Size(44, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: () {
        setSheetState(() {
          widget.orientationService.nudgeHeadingOffset(delta);
        });
        widget.preferencesService?.saveHeadingOffset(
          widget.orientationService.calibration.manualHeadingOffset,
        );
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _calibrationResetButton(
    String label,
    Color accent,
    Color textPrimary,
    StateSetter setSheetState,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        minimumSize: const Size(60, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: () {
        setSheetState(() {
          widget.orientationService.setManualCalibrationOffset(0.0);
        });
        widget.preferencesService?.saveHeadingOffset(0.0);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  Future<void> _openTimeSelection() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimeSelectionScreen(
          initialTime: widget.astronomyEngine.time,
          style: _style,
          onTimeChanged: (newTime) {
            widget.astronomyEngine.updateTime(newTime);
          },
        ),
      ),
    );
  }

  void _openStarDetails(Star star) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarDetailsScreen(
          star: star,
          astronomyEngine: widget.astronomyEngine,
          style: _style,
        ),
      ),
    );
  }

  void _openPlanetDetails(Planet planet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarDetailsScreen(
          planet: planet,
          astronomyEngine: widget.astronomyEngine,
          style: _style,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _style.nightMode;
    final textPrimary = _style.textColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    final selectedStar = _selectedStarId != null
        ? widget.starRepository.getStarById(_selectedStarId!)
        : null;
    final selectedPlanet = (_selectedStarId != null && selectedStar == null)
        ? widget.astronomyEngine.getPlanetById(_selectedStarId!)
        : null;
    final selectedConstellation =
        (_selectedStarId != null &&
            selectedStar == null &&
            selectedPlanet == null)
        ? widget.constellationRepository.getConstellationById(_selectedStarId!)
        : null;
    final selectedDeepSkyObject =
        (_selectedStarId != null &&
            selectedStar == null &&
            selectedPlanet == null &&
            selectedConstellation == null)
        ? _deepSkyRepository.getById(_selectedStarId!)
        : null;
    final selectedPosition = selectedStar != null
        ? _computedPositions[selectedStar.id]
        : (selectedPlanet != null
              ? widget.astronomyEngine.solarSystemPositions[selectedPlanet.id]
              : (selectedConstellation != null
                    ? _computedConstellationPositions[selectedConstellation.id]
                    : (selectedDeepSkyObject != null
                          ? _computedDeepSkyPositions[selectedDeepSkyObject.id]
                          : null)));

    final localTime = widget.astronomyEngine.time.localDateTime;
    final timeStr =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          // Construct projection matrix for current frame
          final projection = SkyProjection(
            centerAzimuth: widget.orientationService.azimuth,
            centerAltitude: widget.orientationService.altitude,
            rollAngle: widget.orientationService.roll,
            fieldOfView: _fieldOfView,
            viewportSize: viewportSize,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Interactive Star Canvas with Touch Pan & Pinch Zoom
              GestureDetector(
                onScaleStart: (details) => _onScaleStart(details, viewportSize),
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onTapUp: _onTapUp,
                child: CustomPaint(
                  size: viewportSize,
                  painter: StarMapPainter(
                    stars: widget.starRepository.allStars,
                    starPositions: _computedPositions,
                    planets: widget.astronomyEngine.solarSystemObjects,
                    planetPositions:
                        widget.astronomyEngine.solarSystemPositions,
                    planetImages: _mapAssetsReady
                        ? PlanetDataService.uiImages
                        : null,
                    constellations:
                        widget.constellationRepository.allConstellations,
                    constellationPositions: _computedConstellationPositions,
                    constellationBoundaryPositions:
                        _computedConstellationBoundaryPositions,
                    constellationImages: _mapAssetsReady
                        ? ConstellationAssetService.uiImages
                        : null,
                    deepSkyObjects: _deepSkyRepository.allObjects,
                    deepSkyPositions: _computedDeepSkyPositions,
                    asterisms: famousAsterisms,
                    activeMeteorShowers: _activeMeteorShowers,
                    meteorShowerPositions: _computedMeteorPositions,
                    milkyWayPlanePositions: _computedMilkyWayPlane,
                    projection: projection,
                    style: _style,
                    selectedStarId: _selectedStarId,
                    onRenderedPositions: (positions) {
                      _renderedStarOffsets = positions;
                    },
                  ),
                ),
              ),

              // 2. Top Header Bar (App Title, Location, Time, Search, Settings)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.0,
                left: 12.0,
                right: 12.0,
                child: Row(
                  children: [
                    // Location Chip
                    Expanded(
                      child: LocationIndicator(
                        location: widget.astronomyEngine.location,
                        style: _style,
                        onTap: _showLocationSelectionSheet,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Time Chip
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openTimeSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isNight
                                      ? const Color(0xFF250404)
                                      : const Color(0xFF0D1627))
                                  .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isNight
                                ? const Color(0x66FF3333)
                                : AstroTrackColors.line,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.astronomyEngine.time.isRealTime
                                  ? Icons.schedule
                                  : Icons.history,
                              size: 13.0,
                              color: accent,
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Search Button
                    _topIconButton(
                      icon: Icons.search,
                      tooltip: 'Search celestial objects',
                      isNight: isNight,
                      accent: accent,
                      onPressed: _openSearch,
                    ),

                    const SizedBox(width: 6),

                    // Settings Button
                    _topIconButton(
                      icon: Icons.settings,
                      tooltip: 'Settings',
                      isNight: isNight,
                      accent: accent,
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),

              // 3. Sub-header: Orientation & Heading HUD
              Positioned(
                top: MediaQuery.of(context).padding.top + 54.0,
                left: 14.0,
                child: OrientationIndicator(
                  azimuth: widget.orientationService.azimuth,
                  altitude: widget.orientationService.altitude,
                  isTracking: widget.orientationService.isTrackingActive,
                  accuracy: widget.orientationService.calibration.accuracy,
                  style: _style,
                  onTap: _showHeadingCalibrationSheet,
                ),
              ),

              // 4. Floating Action Controls (Right side)
              Positioned(
                right: 14.0,
                top: MediaQuery.of(context).padding.top + 90.0,
                child: SkyMapControls(
                  style: _style,
                  isTrackingActive: widget.orientationService.isTrackingActive,
                  hasSensors: widget.orientationService.hasSensors,
                  onToggleTracking: () {
                    widget.orientationService.toggleTracking();
                    final isNowTracking =
                        widget.orientationService.isTrackingActive;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isNowTracking
                              ? 'Device Orientation Tracking Active (AR Mode)'
                              : 'Manual Touch Pan Mode Active',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: isNowTracking
                            ? AstroTrackColors.accentStrong
                            : AstroTrackColors.surfaceRaised,
                      ),
                    );
                  },
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onToggleConstellations: () {
                    setState(() {
                      _style = _style.copyWith(
                        showConstellationLines: !_style.showConstellationLines,
                      );
                    });
                    widget.preferencesService?.saveRenderingStyle(_style);
                  },
                  onToggleConstellationArt: () {
                    setState(() {
                      _style = _style.copyWith(
                        showConstellationArt: !_style.showConstellationArt,
                      );
                    });
                    widget.preferencesService?.saveRenderingStyle(_style);
                  },
                  onToggleDeclutter: () {
                    setState(() {
                      _style = _style.copyWith(
                        hideLeastFamousStars: !_style.hideLeastFamousStars,
                      );
                    });
                    widget.preferencesService?.saveRenderingStyle(_style);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _style.hideLeastFamousStars
                              ? 'Declutter mode: Showing famous stars only'
                              : 'Detailed mode: Showing all stars',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AstroTrackColors.accentStrong,
                      ),
                    );
                  },
                  onToggleGrid: () {
                    setState(() {
                      _style = _style.copyWith(
                        showCelestialGrid: !_style.showCelestialGrid,
                      );
                    });
                    widget.preferencesService?.saveRenderingStyle(_style);
                  },
                  onToggleNightMode: () {
                    setState(() {
                      _style = _style.copyWith(nightMode: !_style.nightMode);
                    });
                    widget.preferencesService?.saveRenderingStyle(_style);
                  },
                  onResetView: () {
                    widget.orientationService.lookAt(
                      azimuth: widget.orientationService.azimuth,
                      altitude: 85.0, // Look up at zenith
                    );
                  },
                ),
              ),

              // 5. Selected Star, Planet, or Constellation Information Card (Bottom above floating nav bar)
              if (selectedStar != null ||
                  selectedPlanet != null ||
                  selectedConstellation != null ||
                  selectedDeepSkyObject != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 94.0,
                  child: StarInformationCard(
                    star: selectedStar,
                    planet: selectedPlanet,
                    constellation: selectedConstellation,
                    deepSkyObject: selectedDeepSkyObject,
                    position: selectedPosition,
                    style: _style,
                    onCenterView: () {
                      if (selectedStar != null) {
                        _centerOnStar(selectedStar);
                      } else if (selectedPlanet != null) {
                        _centerOnPlanet(selectedPlanet);
                      } else if (selectedConstellation != null) {
                        _centerOnConstellation(selectedConstellation);
                      } else if (selectedDeepSkyObject != null) {
                        _centerOnDeepSkyObject(selectedDeepSkyObject);
                      }
                    },
                    onFullDetails: () {
                      if (selectedStar != null) {
                        _openStarDetails(selectedStar);
                      } else if (selectedPlanet != null) {
                        _openPlanetDetails(selectedPlanet);
                      } else if (selectedConstellation != null) {
                        _centerOnConstellation(selectedConstellation);
                      } else if (selectedDeepSkyObject != null) {
                        _showDeepSkyDetails(selectedDeepSkyObject);
                      }
                    },
                    onClose: () {
                      setState(() {
                        _selectedStarId = null;
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required String tooltip,
    required bool isNight,
    required Color accent,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: (isNight ? const Color(0xFF250404) : const Color(0xFF0D1627))
            .withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: isNight ? const Color(0x66FF3333) : AstroTrackColors.line,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(icon, size: 18.0, color: accent),
          ),
        ),
      ),
    );
  }
}
