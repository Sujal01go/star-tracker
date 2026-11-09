import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../astronomy/spherical_geometry.dart';
import 'heading_calibration.dart';

/// Service managing device sensors for the sky camera's pointing direction.
/// Features vector-based angular smoothing (eliminating 360°/0° jitter),
/// sensor fusion for altitude pitch and roll, and manual fallback navigation.
class DeviceOrientationService extends ChangeNotifier {
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _azimuth = 0.0; // Heading in degrees [0, 360) clockwise from North
  double _compassAzimuth = 0.0; // Untrimmed magnetic heading from the phone
  double _altitude = 35.0; // Tilt in degrees [-90, +90]
  double _roll = 0.0; // Device roll in degrees
  double _levelPitch =
      0.0; // Flat-screen setup level along the phone's long axis
  double _levelRoll =
      0.0; // Flat-screen setup level across the phone's short axis
  bool _isTrackingActive = true;
  bool _hasStarted = false;
  bool _hasSensors = true;
  bool _invertPitch = false;

  HeadingCalibration _calibration = const HeadingCalibration();

  // Exponential smoothing is based on elapsed time, so motion stays consistent
  // across sensors that report at different rates.
  final Stopwatch _sensorClock = Stopwatch()..start();
  Duration? _lastCompassSampleTime;
  Duration? _lastAccelerometerSampleTime;
  Duration? _lastGyroscopeSampleTime;
  bool _hasCompassHeadingSample = false;
  bool _hasRawCompassHeadingSample = false;
  bool _hasAccelerometerSample = false;
  bool _hasSetupLevelSample = false;
  bool _hasGyroscopeSample = false;
  double _smoothAzCos = 1.0;
  double _smoothAzSin = 0.0;
  double _smoothCompassAzCos = 1.0;
  double _smoothCompassAzSin = 0.0;
  double _smoothAlt = 35.0;
  double _smoothRoll = 0.0;
  static const double _smoothingTimeConstant = 0.075;
  static const double _accelerometerTimeConstant = 0.12;
  static const double _gravityCorrectionTimeConstant = 0.65;
  static const double _rollTimeConstant = 0.22;

  double get azimuth => _azimuth;
  double get compassAzimuth => _compassAzimuth;
  double get altitude => _altitude;
  double get roll => _roll;
  double get levelPitch => _levelPitch;
  double get levelRoll => _levelRoll;
  bool get isTrackingActive => _isTrackingActive;
  bool get hasSensors => _hasSensors;
  bool get invertPitch => _invertPitch;
  HeadingCalibration get calibration => _calibration;

  void setInvertPitch(bool invert) {
    if (_invertPitch != invert) {
      _invertPitch = invert;
      notifyListeners();
    }
  }

  /// Starts listening to hardware compass and accelerometer streams.
  void start() {
    if (_hasStarted) return;
    _hasStarted = true;
    _initSensors();
  }

  void _initSensors() {
    // 1. Compass listener for azimuth heading
    try {
      _compassSub?.cancel();
      _compassSub = FlutterCompass.events?.listen(
        _onCompassEvent,
        onError: (err) {
          debugPrint('Compass error: $err');
          _hasSensors = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Compass initialization failed: $e');
      _hasSensors = false;
    }

    // 2. Accelerometer listener for pitch (altitude) and roll
    try {
      _accelSub?.cancel();
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            _onAccelerometerEvent,
            onError: (err) {
              debugPrint('Accelerometer error: $err');
              _hasSensors = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('Accelerometer initialization failed: $e');
      _hasSensors = false;
    }

    // Gyroscope integration carries quick pitch motion between gravity
    // readings. The accelerometer corrects its slow drift separately.
    try {
      _gyroSub?.cancel();
      _gyroSub =
          gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            _onGyroscopeEvent,
            onError: (err) {
              debugPrint('Gyroscope error: $err');
              _hasGyroscopeSample = false;
              _lastGyroscopeSampleTime = null;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('Gyroscope initialization failed: $e');
      _hasGyroscopeSample = false;
    }
  }

  double? _lastRawHeading;

  double _nextSampleDelta(
    Duration? previousSampleTime, {
    required bool compass,
    bool gyroscope = false,
  }) {
    final now = _sensorClock.elapsed;
    if (compass) {
      _lastCompassSampleTime = now;
    } else if (gyroscope) {
      _lastGyroscopeSampleTime = now;
    } else {
      _lastAccelerometerSampleTime = now;
    }

    if (previousSampleTime == null) return 1.0 / 60.0;
    return ((now - previousSampleTime).inMicroseconds / 1000000.0)
        .clamp(1.0 / 240.0, 0.25)
        .toDouble();
  }

  double _smoothingAlpha(
    double deltaSeconds, {
    double timeConstant = _smoothingTimeConstant,
  }) {
    return (1.0 - math.exp(-deltaSeconds / timeConstant))
        .clamp(0.005, 0.45)
        .toDouble();
  }

  void _onCompassEvent(CompassEvent event) {
    final rawHeading = event.heading;
    if (rawHeading == null || !rawHeading.isFinite) return;
    processCompassData(rawHeading, accuracy: event.accuracy);
  }

  /// Updates the phone compass independently from app-specific sky-map trim.
  void processCompassData(double rawHeading, {double? accuracy}) {
    if (!_isTrackingActive || !rawHeading.isFinite) return;
    _lastRawHeading = rawHeading;

    final sensorHeading = SphericalGeometry.normalizeDegrees360(rawHeading);
    final deltaSeconds = _nextSampleDelta(
      _lastCompassSampleTime,
      compass: true,
    );
    final sensorRad = SphericalGeometry.toRadians(sensorHeading);
    final sensorCos = math.cos(sensorRad);
    final sensorSin = math.sin(sensorRad);

    if (!_hasRawCompassHeadingSample) {
      _smoothCompassAzCos = sensorCos;
      _smoothCompassAzSin = sensorSin;
      _hasRawCompassHeadingSample = true;
    } else {
      final alpha = _smoothingAlpha(deltaSeconds);
      _smoothCompassAzCos =
          (alpha * sensorCos) + ((1.0 - alpha) * _smoothCompassAzCos);
      _smoothCompassAzSin =
          (alpha * sensorSin) + ((1.0 - alpha) * _smoothCompassAzSin);
    }
    _compassAzimuth = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(
        math.atan2(_smoothCompassAzSin, _smoothCompassAzCos),
      ),
    );

    // Apply calibration offset
    final correctedHeading = SphericalGeometry.normalizeDegrees360(
      _compassAzimuth + _calibration.totalOffsetDegrees,
    );

    final rad = SphericalGeometry.toRadians(correctedHeading);
    final curCos = math.cos(rad);
    final curSin = math.sin(rad);

    if (!_hasCompassHeadingSample) {
      // Seed from the actual heading so activation does not ease in from North.
      _smoothAzCos = curCos;
      _smoothAzSin = curSin;
      _hasCompassHeadingSample = true;
    } else {
      final alpha = _smoothingAlpha(deltaSeconds);
      _smoothAzCos = (alpha * curCos) + ((1.0 - alpha) * _smoothAzCos);
      _smoothAzSin = (alpha * curSin) + ((1.0 - alpha) * _smoothAzSin);
    }

    final smoothedRad = math.atan2(_smoothAzSin, _smoothAzCos);
    _azimuth = SphericalGeometry.normalizeDegrees360(
      SphericalGeometry.toDegrees(smoothedRad),
    );

    // Update sensor accuracy
    final acc = accuracy;
    SensorAccuracy sensorAcc = SensorAccuracy.unreliable;
    if (acc != null) {
      if (acc <= 15) {
        sensorAcc = SensorAccuracy.high;
      } else if (acc <= 30) {
        sensorAcc = SensorAccuracy.medium;
      } else {
        sensorAcc = SensorAccuracy.low;
      }
    }

    _calibration = _calibration.copyWith(
      accuracy: sensorAcc,
      samplesCount: _calibration.samplesCount + 1,
    );

    notifyListeners();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isTrackingActive) return;
    final deltaSeconds = _nextSampleDelta(
      _lastAccelerometerSampleTime,
      compass: false,
    );
    processAccelerometerData(
      event.x,
      event.y,
      event.z,
      deltaSeconds: deltaSeconds,
    );
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isTrackingActive || !event.x.isFinite) return;

    final deltaSeconds = _nextSampleDelta(
      _lastGyroscopeSampleTime,
      compass: false,
      gyroscope: true,
    );
    _hasGyroscopeSample = true;

    final pitchRate = _invertPitch ? -event.x : event.x;
    _smoothAlt = SphericalGeometry.clamp(
      _smoothAlt + SphericalGeometry.toDegrees(pitchRate * deltaSeconds),
      -90.0,
      90.0,
    );
    _altitude = _smoothAlt;
    notifyListeners();
  }

  /// Calculates horizontal altitude (pitch) and roll from 3-axis accelerometer readings.
  ///
  /// Coordinate frame (Portrait mode):
  /// - +X = right edge of phone
  /// - +Y = top edge of phone
  /// - +Z = front screen pointing towards the observer
  /// - The camera/viewfinder line of sight points along -Z (into the sky).
  ///
  /// Altitude physics:
  /// - Holding phone vertically at horizon: y ≈ +9.8, z ≈ 0 => alt = 0°.
  /// - Moving/tilting phone upward towards zenith (+90°): top tilts back, screen tilts down,
  ///   accelerometer measures reaction force z < 0. Thus the true elevation angle is -z.
  /// - Pointing straight at zenith: z = -9.8 => alt = +90°.
  /// - Pointing down at feet/nadir: z = +9.8 => alt = -90°.
  void processAccelerometerData(
    double x,
    double y,
    double z, {
    double deltaSeconds = 1.0 / 60.0,
  }) {
    if (!x.isFinite || !y.isFinite || !z.isFinite) return;

    // A phone's linear acceleration is not gravity. Reject strong movement
    // spikes so they cannot pull the absolute pitch reference away from the
    // gyroscope's short-term estimate.
    final accelerationMagnitude = math.sqrt(x * x + y * y + z * z);
    if (accelerationMagnitude < 7.0 || accelerationMagnitude > 12.5) return;

    final horizNorm = math.sqrt(x * x + y * y);
    final effectiveZ = _invertPitch ? z : -z;
    final rawAlt = SphericalGeometry.toDegrees(
      math.atan2(effectiveZ, horizNorm),
    );

    // Setup level assumes the phone lies screen-up or screen-down on the
    // telescope tube/mount. In that pose, gravity is mostly on Z, while X/Y
    // components show the two slopes of the phone's screen plane. This is a
    // different coordinate frame from the sky-map camera altitude above.
    final rawLevelPitch = SphericalGeometry.toDegrees(
      math.atan2(y, math.sqrt(x * x + z * z)),
    );
    final rawLevelRoll = SphericalGeometry.toDegrees(
      math.atan2(-x, math.sqrt(y * y + z * z)),
    );
    if (!_hasSetupLevelSample) {
      _levelPitch = rawLevelPitch;
      _levelRoll = rawLevelRoll;
      _hasSetupLevelSample = true;
    } else {
      final levelAlpha = _smoothingAlpha(
        deltaSeconds,
        timeConstant: _accelerometerTimeConstant,
      );
      _levelPitch += levelAlpha * (rawLevelPitch - _levelPitch);
      _levelRoll += levelAlpha * (rawLevelRoll - _levelRoll);
    }

    // Use gravity as a gentle absolute reference. When the gyroscope is
    // available, the longer correction window removes drift without feeding
    // hand acceleration and sensor noise straight into the camera.
    if (!_hasAccelerometerSample) {
      _smoothAlt = rawAlt;
      _hasAccelerometerSample = true;
    } else {
      final correctionAlpha = _smoothingAlpha(
        deltaSeconds,
        timeConstant: _hasGyroscopeSample
            ? _gravityCorrectionTimeConstant
            : _accelerometerTimeConstant,
      );
      _smoothAlt += correctionAlpha * (rawAlt - _smoothAlt);
    }

    // Roll is estimated from gravity only while it is informative. Near the
    // zenith/nadir, gravity aligns with the camera axis and roll is ambiguous.
    final stableAltitude = _smoothAlt.abs();
    final rollDamping = math.cos(SphericalGeometry.toRadians(stableAltitude));
    final rawRoll =
        SphericalGeometry.toDegrees(math.atan2(-x, y)) * rollDamping;
    final rollDelta = SphericalGeometry.normalizeDegrees180(
      rawRoll - _smoothRoll,
    );
    final rollAlpha = _smoothingAlpha(
      deltaSeconds,
      timeConstant: _rollTimeConstant,
    );
    _smoothRoll = SphericalGeometry.normalizeDegrees180(
      _smoothRoll + (rollAlpha * rollDelta),
    );

    _altitude = SphericalGeometry.clamp(_smoothAlt, -90.0, 90.0);
    _roll = _smoothRoll;

    notifyListeners();
  }

  /// Toggles orientation sensor tracking mode.
  void toggleTracking() {
    setTracking(!_isTrackingActive);
  }

  void setTracking(bool active) {
    if (_isTrackingActive != active) {
      _isTrackingActive = active;
      if (active) {
        _lastCompassSampleTime = null;
        _lastAccelerometerSampleTime = null;
        _lastGyroscopeSampleTime = null;
        _hasCompassHeadingSample = false;
        _hasRawCompassHeadingSample = false;
      }
      notifyListeners();
    }
  }

  /// Applies a camera pose produced by a perspective trackball drag.
  void setManualViewPose({
    required double azimuth,
    required double altitude,
    required double roll,
  }) {
    _isTrackingActive = false;
    _azimuth = SphericalGeometry.normalizeDegrees360(azimuth);
    _altitude = SphericalGeometry.clamp(altitude, -89.9, 89.9);
    _roll = SphericalGeometry.normalizeDegrees180(roll);

    _smoothAzCos = math.cos(SphericalGeometry.toRadians(_azimuth));
    _smoothAzSin = math.sin(SphericalGeometry.toRadians(_azimuth));
    _smoothAlt = _altitude;
    _smoothRoll = _roll;

    notifyListeners();
  }

  /// Manually adjusts azimuth and altitude (e.g. from touch drag gestures).
  void manualPan({
    required double deltaAzimuth,
    required double deltaAltitude,
  }) {
    if (_isTrackingActive) {
      // Disengage sensor tracking when user drags manually
      _isTrackingActive = false;
    }

    _azimuth = SphericalGeometry.normalizeDegrees360(_azimuth + deltaAzimuth);
    final effDeltaAlt = _invertPitch ? -deltaAltitude : deltaAltitude;
    _altitude = SphericalGeometry.clamp(_altitude + effDeltaAlt, -89.9, 89.9);

    _smoothAzCos = math.cos(SphericalGeometry.toRadians(_azimuth));
    _smoothAzSin = math.sin(SphericalGeometry.toRadians(_azimuth));
    _smoothAlt = _altitude;

    notifyListeners();
  }

  /// Sets manual heading offset calibration in degrees.
  /// Immediately recalculates the active azimuth so canvas updates in real time.
  void setManualCalibrationOffset(double offsetDegrees) {
    final oldOffset = _calibration.manualHeadingOffset;
    _calibration = _calibration.copyWith(manualHeadingOffset: offsetDegrees);

    if (_lastRawHeading != null && _isTrackingActive) {
      final correctedHeading = SphericalGeometry.normalizeDegrees360(
        _lastRawHeading! + _calibration.totalOffsetDegrees,
      );
      _smoothAzCos = math.cos(SphericalGeometry.toRadians(correctedHeading));
      _smoothAzSin = math.sin(SphericalGeometry.toRadians(correctedHeading));
      _azimuth = correctedHeading;
    } else {
      final delta = offsetDegrees - oldOffset;
      _azimuth = SphericalGeometry.normalizeDegrees360(_azimuth + delta);
      _smoothAzCos = math.cos(SphericalGeometry.toRadians(_azimuth));
      _smoothAzSin = math.sin(SphericalGeometry.toRadians(_azimuth));
    }
    notifyListeners();
  }

  /// Nudges manual heading offset by a delta in degrees (e.g. +1.0° or -5.0°).
  void nudgeHeadingOffset(double deltaDegrees) {
    final newOffset = SphericalGeometry.clamp(
      _calibration.manualHeadingOffset + deltaDegrees,
      -180.0,
      180.0,
    );
    setManualCalibrationOffset(newOffset);
  }

  /// Centers the sky view on a specific sky position (e.g. selected star).
  void lookAt({required double azimuth, required double altitude}) {
    _isTrackingActive = false;
    _azimuth = SphericalGeometry.normalizeDegrees360(azimuth);
    _altitude = SphericalGeometry.clamp(altitude, -89.9, 89.9);

    _smoothAzCos = math.cos(SphericalGeometry.toRadians(_azimuth));
    _smoothAzSin = math.sin(SphericalGeometry.toRadians(_azimuth));
    _smoothAlt = _altitude;

    notifyListeners();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}
