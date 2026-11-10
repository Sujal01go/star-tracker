import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;

import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/star_catalogue_repository.dart';
import '../models/observation_time.dart';
import '../models/observer_location.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import '../widgets/planet_thumbnail.dart';

/// Observing dashboard for live sky movement, upcoming targets, and planning.
class SolarSystemHomeScreen extends StatefulWidget {
  final AstronomyEngine astronomyEngine;
  final StarCatalogueRepository starRepository;
  final bool isActive;
  final VoidCallback onOpenSkyMap;
  final void Function(Planet planet) onTrackPlanet;
  final void Function(Star star)? onTrackStar;
  final VoidCallback onOpenTelescope;
  final VoidCallback onOpenDrawer;

  const SolarSystemHomeScreen({
    super.key,
    required this.astronomyEngine,
    required this.starRepository,
    required this.isActive,
    required this.onOpenSkyMap,
    required this.onTrackPlanet,
    this.onTrackStar,
    required this.onOpenTelescope,
    required this.onOpenDrawer,
  });

  @override
  State<SolarSystemHomeScreen> createState() => _SolarSystemHomeScreenState();
}

class _SolarSystemHomeScreenState extends State<SolarSystemHomeScreen> {
  static const _usefulAltitude = 20.0;
  static const _sampleMinutes = 10;
  static const _forecastSteps = 18;
  static const _sessionDurations = [30, 60, 90];

  int _sessionMinutes = 60;
  final List<String> _plannedTargetIds = [];
  List<Star>? _catalogueTargets;
  String? _forecastCacheKey;
  String? _requestedForecastKey;
  String? _forecastError;
  bool _forecastLoading = false;
  DateTime? _forecastStart;
  List<_TargetForecast> _forecastCache = const [];

  @override
  void initState() {
    super.initState();
    widget.astronomyEngine.addListener(_onAstronomyChanged);
  }

  @override
  void didUpdateWidget(covariant SolarSystemHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.astronomyEngine != widget.astronomyEngine) {
      oldWidget.astronomyEngine.removeListener(_onAstronomyChanged);
      widget.astronomyEngine.addListener(_onAstronomyChanged);
      _clearForecastCache();
    }
    if (oldWidget.starRepository != widget.starRepository) {
      _catalogueTargets = null;
      _clearForecastCache();
    }
  }

  @override
  void dispose() {
    widget.astronomyEngine.removeListener(_onAstronomyChanged);
    super.dispose();
  }

  void _onAstronomyChanged() {
    if (mounted && widget.isActive) setState(() {});
  }

  void _clearForecastCache() {
    _forecastCacheKey = null;
    _requestedForecastKey = null;
    _forecastError = null;
    _forecastLoading = false;
    _forecastStart = null;
    _forecastCache = const [];
  }

  List<_ObservingTarget> _targets() {
    final planets = widget.astronomyEngine.planets
        .where((planet) => !planet.isSun && planet.type != PlanetType.earth)
        .map(_ObservingTarget.forPlanet);
    final stars =
        (_catalogueTargets ??=
                widget.starRepository.allStars
                    .where(
                      (star) => star.isFamous && star.apparentMagnitude <= 3.0,
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        a.apparentMagnitude.compareTo(b.apparentMagnitude),
                  ))
            .take(24)
            .map(_ObservingTarget.forStar);

    return [...planets, ...stars];
  }

  Map<String, SkyPosition> _currentPositions(List<_ObservingTarget> targets) {
    final positions = <String, SkyPosition>{};
    final stars = <Star>[];
    for (final target in targets) {
      if (target.planet case final planet?) {
        final position = widget.astronomyEngine.solarSystemPositions[planet.id];
        if (position != null) positions[target.id] = position;
      } else if (target.star case final star?) {
        stars.add(star);
      }
    }
    positions.addAll(widget.astronomyEngine.computeBatch(stars));
    return positions;
  }

  String _forecastKey(List<_ObservingTarget> targets) {
    final engine = widget.astronomyEngine;
    final now = engine.time.utcDateTime;
    final location = engine.location;
    final timeBucket = now.minute ~/ 5;
    final key = [
      now.year,
      now.month,
      now.day,
      now.hour,
      timeBucket,
      location.latitude.toStringAsFixed(4),
      location.longitude.toStringAsFixed(4),
      location.altitudeMeters.toStringAsFixed(0),
      targets.map((target) => target.id).join(','),
    ].join('|');
    return key;
  }

  void _scheduleForecasts(List<_ObservingTarget> targets, String key) {
    if (_forecastCacheKey == key || _requestedForecastKey == key) return;

    _requestedForecastKey = key;
    final engine = widget.astronomyEngine;
    final baseTime = engine.time.utcDateTime;
    final location = engine.location;
    final payload = <String, Object?>{
      'utcMillis': baseTime.millisecondsSinceEpoch,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'altitudeMeters': location.altitudeMeters,
      'targets': [
        for (final target in targets)
          {
            'id': target.id,
            'isPlanet': target.planet != null,
            'rightAscension':
                target.planet?.rightAscension ?? target.star!.rightAscension,
            'declination':
                target.planet?.declination ?? target.star!.declination,
            'magnitude': target.star?.apparentMagnitude ?? 0.0,
            'coordinateEpoch': target.star?.coordinateEpoch ?? 2000.0,
            'properMotionRa': target.star?.properMotionRaMasYr,
            'properMotionDec': target.star?.properMotionDecMasYr,
          },
      ],
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.isActive || _requestedForecastKey != key) {
        if (_requestedForecastKey == key) _requestedForecastKey = null;
        return;
      }
      setState(() {
        _forecastLoading = true;
        _forecastError = null;
      });
      compute<Map<String, Object?>, List<Map<String, Object?>>>(
            _calculateForecasts,
            payload,
            debugLabel: 'sky session forecast',
          )
          .then((rows) {
            if (!mounted || _requestedForecastKey != key) return;
            final targetsById = {
              for (final target in targets) target.id: target,
            };
            setState(() {
              _forecastStart = baseTime;
              _forecastCache = [
                for (final row in rows)
                  if (targetsById[row['id']] case final target?)
                    _TargetForecast(
                      target,
                      (row['altitudes'] as List<Object?>)
                          .map((altitude) => (altitude as num?)?.toDouble())
                          .toList(growable: false),
                    ),
              ];
              _forecastCacheKey = key;
              _forecastLoading = false;
              _forecastError = null;
            });
          })
          .catchError((Object error) {
            if (!mounted || _requestedForecastKey != key) return;
            setState(() {
              _forecastLoading = false;
              _forecastError = 'Could not calculate the sky forecast.';
            });
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    final targets = _targets();
    final positions = _currentPositions(targets);
    final key = _forecastKey(targets);
    _scheduleForecasts(targets, key);
    final forecastReady = _forecastCacheKey == key;
    final forecasts = forecastReady
        ? _forecastCache
        : const <_TargetForecast>[];
    final now = widget.astronomyEngine.time.localDateTime;
    final visibleCount = targets
        .where((target) => (positions[target.id]?.altitude ?? -90) >= 0)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AstroTrackColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${widget.astronomyEngine.location.name}  ·  ${_dateLabel(now)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AstroTrackColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$visibleCount above horizon',
                    style: const TextStyle(
                      color: AstroTrackColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _buildMovementSection(forecasts, positions, forecastReady),
              const SizedBox(height: 28),
              _buildComingUpSection(forecasts, positions, forecastReady),
              const SizedBox(height: 28),
              _buildPlannerSection(forecasts, positions, forecastReady),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Open menu',
          onPressed: widget.onOpenDrawer,
          icon: const Icon(Icons.menu, size: 24),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Tonight',
            style: TextStyle(
              color: AstroTrackColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Telescope setup',
          onPressed: widget.onOpenTelescope,
          icon: const Icon(
            Icons.tune,
            color: AstroTrackColors.accent,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildMovementSection(
    List<_TargetForecast> forecasts,
    Map<String, SkyPosition> positions,
    bool forecastReady,
  ) {
    final moving = <_MovementItem>[];
    for (final forecast in forecasts) {
      final current = positions[forecast.target.id];
      final later = forecast.altitudeAt(3);
      if (current == null || later == null || current.altitude < 0) continue;
      moving.add(_MovementItem(forecast, current, later - current.altitude));
    }
    moving.sort((a, b) => b.change.abs().compareTo(a.change.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'What’s moving',
          'Altitude change over the next 30 minutes',
        ),
        const SizedBox(height: 10),
        if (!forecastReady)
          _forecastStatus()
        else if (moving.isEmpty)
          _emptyMessage(
            'Nothing is above the horizon right now. Check what reaches useful height next.',
            actionLabel: 'Open sky map',
            onAction: widget.onOpenSkyMap,
          )
        else
          ...moving.take(4).map((item) {
            final trend = item.change > 0.6
                ? 'Climbing'
                : item.change < -0.6
                ? 'Setting'
                : 'Near its highest point';
            final signedChange = item.change >= 0 ? '+' : '−';
            return _targetRow(
              item.forecast.target,
              onTap: () => _openTarget(item.forecast.target),
              detail:
                  '${item.current.altitude.toStringAsFixed(0)}° now  →  ${item.laterAltitude.toStringAsFixed(0)}° in 30 min',
              trailing: Semantics(
                label:
                    '$trend ${item.change.abs().toStringAsFixed(0)} degrees in 30 minutes',
                child: Text(
                  '$signedChange${item.change.abs().toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: AstroTrackColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildComingUpSection(
    List<_TargetForecast> forecasts,
    Map<String, SkyPosition> positions,
    bool forecastReady,
  ) {
    final upcoming = <_UpcomingTarget>[];
    for (final forecast in forecasts) {
      final currentAltitude = positions[forecast.target.id]?.altitude;
      if (currentAltitude == null || currentAltitude >= _usefulAltitude) {
        continue;
      }
      for (var step = 1; step <= _forecastSteps; step++) {
        final altitude = forecast.altitudeAt(step);
        if (altitude != null && altitude >= _usefulAltitude) {
          upcoming.add(
            _UpcomingTarget(
              forecast.target,
              step,
              altitude,
              _forecastStart!.add(Duration(minutes: step * _sampleMinutes)),
            ),
          );
          break;
        }
      }
    }
    upcoming.sort((a, b) => a.step.compareTo(b.step));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Coming up',
          'Bright targets reaching a useful viewing height',
        ),
        const SizedBox(height: 10),
        if (!forecastReady)
          _forecastStatus()
        else if (upcoming.isEmpty)
          _emptyMessage(
            'No bright target reaches 20° altitude in the next three hours.',
            actionLabel: 'Browse the sky',
            onAction: widget.onOpenSkyMap,
          )
        else ...[
          ...upcoming.take(4).map((item) {
            return _targetRow(
              item.target,
              onTap: () => _openTarget(item.target),
              detail: 'Reaches 20° around ${_timeLabel(item.at)}',
              trailing: Text(
                '${item.altitude.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: AstroTrackColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Times are estimates based on the current catalogue positions.',
            style: TextStyle(
              color: AstroTrackColors.textMuted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlannerSection(
    List<_TargetForecast> forecasts,
    Map<String, SkyPosition> positions,
    bool forecastReady,
  ) {
    final durationSteps = (_sessionMinutes / _sampleMinutes).round();
    final endTime = widget.astronomyEngine.time.utcDateTime.add(
      Duration(minutes: _sessionMinutes),
    );
    final plans = <_SessionCandidate>[];

    for (final forecast in forecasts) {
      final currentAltitude = positions[forecast.target.id]?.altitude;
      if (currentAltitude == null) continue;
      final altitudes = <double>[currentAltitude];
      for (var step = 1; step <= durationSteps; step++) {
        final altitude = forecast.altitudeAt(step);
        if (altitude != null) altitudes.add(altitude);
      }
      if (altitudes.length < 2) continue;
      plans.add(
        _SessionCandidate(
          forecast.target,
          altitudes.reduce((a, b) => a < b ? a : b),
          altitudes.reduce((a, b) => a > b ? a : b),
        ),
      );
    }
    plans.sort((a, b) {
      final aStatus = a.lowestAltitude >= _usefulAltitude ? 0 : 1;
      final bStatus = b.lowestAltitude >= _usefulAltitude ? 0 : 1;
      final byUsability = aStatus.compareTo(bStatus);
      if (byUsability != 0) return byUsability;
      return b.lowestAltitude.compareTo(a.lowestAltitude);
    });

    final chosen = plans
        .map((candidate) => candidate.target)
        .where((target) => _plannedTargetIds.contains(target.id))
        .toList();
    final firstChosen = chosen.isEmpty ? null : chosen.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Session planner',
          'Choose a duration and build a target list for now.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sessionDurations.map((minutes) {
            final selected = minutes == _sessionMinutes;
            return ChoiceChip(
              label: Text('$minutes min'),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _sessionMinutes = minutes),
              backgroundColor: AstroTrackColors.surface,
              selectedColor: AstroTrackColors.accentSoft,
              side: BorderSide(
                color: selected
                    ? AstroTrackColors.accent
                    : AstroTrackColors.line,
              ),
              labelStyle: TextStyle(
                color: selected
                    ? AstroTrackColors.textPrimary
                    : AstroTrackColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: const StadiumBorder(),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${chosen.length} ${chosen.length == 1 ? 'target' : 'targets'}  ·  Ends ${_timeLabel(endTime)}',
                style: const TextStyle(
                  color: AstroTrackColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            if (chosen.isNotEmpty)
              TextButton(
                onPressed: () => setState(_plannedTargetIds.clear),
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!forecastReady)
          _forecastStatus()
        else if (plans.isEmpty)
          _emptyMessage(
            'The catalogue has no bright targets for this observing window.',
            actionLabel: 'Open sky map',
            onAction: widget.onOpenSkyMap,
          )
        else
          ...plans.take(6).map((candidate) {
            final isPlanned = _plannedTargetIds.contains(candidate.target.id);
            final staysHigh = candidate.lowestAltitude >= _usefulAltitude;
            final detail = staysHigh
                ? 'Above 20° for the full session · low point ${candidate.lowestAltitude.toStringAsFixed(0)}°'
                : candidate.highestAltitude >= _usefulAltitude
                ? 'Below 20° for part of the session · high point ${candidate.highestAltitude.toStringAsFixed(0)}°'
                : 'Below 20° during this session';
            return _targetRow(
              candidate.target,
              onTap: () => _togglePlannedTarget(candidate.target),
              detail: detail,
              trailing: Checkbox(
                value: isPlanned,
                onChanged: (_) => _togglePlannedTarget(candidate.target),
                activeColor: AstroTrackColors.action,
                checkColor: AstroTrackColors.background,
                side: const BorderSide(color: AstroTrackColors.line),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: firstChosen == null
                ? widget.onOpenSkyMap
                : () => _openTarget(firstChosen),
            icon: const Icon(Icons.radar, size: 19),
            label: Text(
              firstChosen == null ? 'Open sky map' : 'Start observing',
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AstroTrackColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AstroTrackColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _targetRow(
    _ObservingTarget target, {
    required VoidCallback onTap,
    required String detail,
    required Widget trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _targetMarker(target),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AstroTrackColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AstroTrackColors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _targetMarker(_ObservingTarget target) {
    if (target.planet case final planet?) {
      return PlanetThumbnail(planetName: planet.name, size: 34);
    }
    final color = target.star!.color;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.star_rounded, color: color, size: 19),
    );
  }

  Widget _forecastStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        _forecastError ??
            (_forecastLoading
                ? 'Calculating local sky windows…'
                : 'Preparing local sky windows…'),
        style: TextStyle(
          color: _forecastError == null
              ? AstroTrackColors.textMuted
              : AstroTrackColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _emptyMessage(
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AstroTrackColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _togglePlannedTarget(_ObservingTarget target) {
    setState(() {
      if (_plannedTargetIds.contains(target.id)) {
        _plannedTargetIds.remove(target.id);
      } else {
        _plannedTargetIds.add(target.id);
      }
    });
  }

  void _openTarget(_ObservingTarget target) {
    if (target.planet case final planet?) {
      widget.onTrackPlanet(planet);
    } else if (target.star case final star?) {
      if (widget.onTrackStar != null) {
        widget.onTrackStar!(star);
      } else {
        widget.onOpenSkyMap();
      }
    }
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _timeLabel(DateTime time) =>
      TimeOfDay.fromDateTime(time.toLocal()).format(context);
}

class _ObservingTarget {
  final Planet? planet;
  final Star? star;

  const _ObservingTarget.forPlanet(Planet value) : planet = value, star = null;

  const _ObservingTarget.forStar(Star value) : planet = null, star = value;

  String get id => planet?.id ?? star!.id;
  String get name => planet?.name ?? star!.displayName;
}

class _TargetForecast {
  final _ObservingTarget target;
  final List<double?> altitudes;

  const _TargetForecast(this.target, this.altitudes);

  double? altitudeAt(int step) =>
      step >= 0 && step < altitudes.length ? altitudes[step] : null;
}

class _MovementItem {
  final _TargetForecast forecast;
  final SkyPosition current;
  final double change;

  const _MovementItem(this.forecast, this.current, this.change);

  double get laterAltitude => current.altitude + change;
}

class _UpcomingTarget {
  final _ObservingTarget target;
  final int step;
  final double altitude;
  final DateTime at;

  const _UpcomingTarget(this.target, this.step, this.altitude, this.at);
}

class _SessionCandidate {
  final _ObservingTarget target;
  final double lowestAltitude;
  final double highestAltitude;

  const _SessionCandidate(
    this.target,
    this.lowestAltitude,
    this.highestAltitude,
  );
}

/// Runs the comparatively expensive time samples in a background isolate.
List<Map<String, Object?>> _calculateForecasts(Map<String, Object?> payload) {
  final targets = (payload['targets'] as List)
      .map((value) => Map<String, Object?>.from(value as Map))
      .toList(growable: false);
  final location = ObserverLocation(
    latitude: (payload['latitude'] as num).toDouble(),
    longitude: (payload['longitude'] as num).toDouble(),
    altitudeMeters: (payload['altitudeMeters'] as num).toDouble(),
    name: 'Forecast location',
  );
  final start = DateTime.fromMillisecondsSinceEpoch(
    payload['utcMillis'] as int,
    isUtc: true,
  );
  final altitudes = <String, List<double?>>{
    for (final target in targets)
      target['id'] as String: List<double?>.filled(
        _SolarSystemHomeScreenState._forecastSteps + 1,
        null,
      ),
  };

  for (
    var step = 0;
    step <= _SolarSystemHomeScreenState._forecastSteps;
    step++
  ) {
    final time = start.add(
      Duration(minutes: step * _SolarSystemHomeScreenState._sampleMinutes),
    );
    final engine = AstronomyEngine(
      location: location,
      time: ObservationTime.manual(time),
    );
    try {
      for (final target in targets) {
        final id = target['id'] as String;
        final SkyPosition? position;
        if (target['isPlanet'] == true) {
          position = engine.solarSystemPositions[id];
        } else {
          position = engine.computeStarPosition(
            Star(
              id: id,
              rightAscension: (target['rightAscension'] as num).toDouble(),
              declination: (target['declination'] as num).toDouble(),
              apparentMagnitude: (target['magnitude'] as num).toDouble(),
              coordinateEpoch: (target['coordinateEpoch'] as num).toDouble(),
              properMotionRaMasYr: (target['properMotionRa'] as num?)
                  ?.toDouble(),
              properMotionDecMasYr: (target['properMotionDec'] as num?)
                  ?.toDouble(),
            ),
          );
        }
        if (position != null) altitudes[id]![step] = position.altitude;
      }
    } finally {
      engine.dispose();
    }
  }

  return [
    for (final target in targets)
      {'id': target['id'] as String, 'altitudes': altitudes[target['id']]!},
  ];
}
