import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../astronomy/spherical_geometry.dart';
import '../models/sky_position.dart';

/// Camera-perspective spherical projection from horizontal sky coordinates (Az, Alt)
/// to 2D screen coordinates.
///
/// Features:
/// - Mathematically correct 3D perspective projection onto the viewport.
/// - Unbroken Great Circle lines (ideal for constellation outlines and coordinate grids).
/// - Automatic clipping of objects behind or beyond the camera field of view.
/// - Seamless 360° azimuth wrapping and zenith handling without edge distortion.
class SkyProjection {
  static final Expando<Vector3> _skyDirectionCache = Expando<Vector3>(
    'sky map unit direction',
  );

  final double centerAzimuth; // in degrees [0, 360)
  final double centerAltitude; // in degrees [-90, +90]
  final double rollAngle; // in degrees
  final double fieldOfView; // in degrees (e.g. 60° to 90°)
  final Size viewportSize;

  late final Vector3 _forwardVector;
  late final Vector3 _rightVector;
  late final Vector3 _upVector;
  late final double _focalLength;

  SkyProjection({
    required this.centerAzimuth,
    required this.centerAltitude,
    this.rollAngle = 0.0,
    required this.fieldOfView,
    required this.viewportSize,
  }) {
    _initProjectionMatrix();
  }

  void _initProjectionMatrix() {
    // 1. Forward unit vector (camera gaze direction)
    // Topocentric: X = East, Y = North, Z = Zenith
    _forwardVector = SphericalGeometry.horizontalToUnitVector(
      centerAzimuth,
      centerAltitude,
    ).normalized();

    // 2. Reference zenith direction
    final zenith = Vector3(0.0, 0.0, 1.0);

    // Use the same azimuth basis at zenith and nadir. The negative sign at the
    // nadir used to flip the entire view by 180 degrees near the lower pole.
    final azRad = SphericalGeometry.toRadians(centerAzimuth);
    Vector3 right;
    if (_forwardVector.z.abs() > 0.999) {
      right = Vector3(math.cos(azRad), -math.sin(azRad), 0.0);
    } else {
      right = _forwardVector.cross(zenith).normalized();
    }

    // Camera Up vector perpendicular to Forward and Right
    Vector3 up = right.cross(_forwardVector).normalized();

    // 3. Apply camera roll if present
    if (rollAngle.abs() > 0.001) {
      final rollRad = SphericalGeometry.toRadians(rollAngle);
      final cosRoll = math.cos(rollRad);
      final sinRoll = math.sin(rollRad);
      final rotatedRight = (right * cosRoll) + (up * sinRoll);
      final rotatedUp = (up * cosRoll) - (right * sinRoll);
      right = rotatedRight.normalized();
      up = rotatedUp.normalized();
    }

    _rightVector = right;
    _upVector = up;

    // 4. Perspective focal length: screen pixels corresponding to 1 radian
    final fovRad = SphericalGeometry.toRadians(fieldOfView);
    final minDim = math.min(viewportSize.width, viewportSize.height);
    _focalLength = (minDim / 2.0) / math.tan(fovRad / 2.0);
  }

  /// Projects a horizontal sky coordinate (azimuth, altitude) onto screen pixels.
  /// Returns `null` if the object is behind the camera or outside the projection cone.
  Offset? projectSkyPosition(SkyPosition skyPos) {
    final direction = _skyDirectionCache[skyPos] ??=
        SphericalGeometry.horizontalToUnitVector(
          skyPos.azimuth,
          skyPos.altitude,
        ).normalized();
    return _projectDirection(direction);
  }

  /// Projects azimuth and altitude in degrees directly onto screen pixels.
  Offset? projectCoordinates(double azimuthDeg, double altitudeDeg) {
    final direction = SphericalGeometry.horizontalToUnitVector(
      azimuthDeg,
      altitudeDeg,
    );
    return _projectDirection(direction);
  }

  Offset? _projectDirection(Vector3 starVec) {
    // Coordinate decomposition along camera axes
    final zCam = starVec.dot(_forwardVector);

    // Behind camera or too close to 90° clip plane
    if (zCam <= 0.08) {
      return null;
    }

    final xCam = starVec.dot(_rightVector);
    final yCam = starVec.dot(_upVector);

    final xScreen = (viewportSize.width / 2.0) + (_focalLength * (xCam / zCam));
    final yScreen =
        (viewportSize.height / 2.0) - (_focalLength * (yCam / zCam));

    // Optional margin check for fast viewport culling
    const margin = 80.0;
    if (xScreen < -margin ||
        xScreen > viewportSize.width + margin ||
        yScreen < -margin ||
        yScreen > viewportSize.height + margin) {
      return null;
    }

    return Offset(xScreen, yScreen);
  }

  /// Inverse projection: Converts screen pixel coordinates (x, y) back into
  /// horizontal sky coordinates (azimuth, altitude) in degrees.
  SkyPosition? unprojectScreenCoordinates(Offset screenPos) {
    final direction = _directionThroughScreenPoint(screenPos);
    final res = SphericalGeometry.unitVectorToHorizontal(direction);
    return SkyPosition(azimuth: res.azimuth, altitude: res.altitude);
  }

  /// Rotates the camera in 3D so the point under [previousPosition] follows
  /// the finger to [currentPosition]. The returned roll is part of the
  /// trackball motion, so dragging near the edge of the sky naturally rolls
  /// the view instead of forcing everything into horizontal/vertical axes.
  ({double azimuth, double altitude, double roll})? panByScreenDrag(
    Offset previousPosition,
    Offset currentPosition,
  ) {
    final anchoredDirection = _directionThroughScreenPoint(previousPosition);
    final draggedDirection = _directionThroughScreenPoint(currentPosition);
    final cross = draggedDirection.cross(anchoredDirection);
    final sinAngle = cross.length;

    if (sinAngle < 1e-9) return null;

    final axis = cross / sinAngle;
    final angle = math.atan2(sinAngle, draggedDirection.dot(anchoredDirection));
    final sinAngleRotation = math.sin(angle);
    final oneMinusCosAngle = 1.0 - math.cos(angle);

    Vector3 rotate(Vector3 vector) {
      return (vector * math.cos(angle)) +
          (axis.cross(vector) * sinAngleRotation) +
          (axis * (axis.dot(vector) * oneMinusCosAngle));
    }

    final forward = rotate(_forwardVector).normalized();
    final right = rotate(_rightVector).normalized();
    final horizontal = SphericalGeometry.unitVectorToHorizontal(forward);
    final azimuth = forward.x.abs() + forward.y.abs() < 1e-6
        ? centerAzimuth
        : horizontal.azimuth;

    // Recover the camera's roll against the local horizon basis. Near the
    // poles, retain the same azimuth-based basis used by the projection.
    Vector3 horizonRight;
    if (forward.z.abs() > 0.999) {
      final azimuthRadians = SphericalGeometry.toRadians(azimuth);
      horizonRight = Vector3(
        math.cos(azimuthRadians),
        -math.sin(azimuthRadians),
        0.0,
      );
    } else {
      horizonRight = forward.cross(Vector3(0.0, 0.0, 1.0)).normalized();
    }
    final horizonUp = horizonRight.cross(forward).normalized();
    final roll = SphericalGeometry.toDegrees(
      math.atan2(right.dot(horizonUp), right.dot(horizonRight)),
    );

    return (azimuth: azimuth, altitude: horizontal.altitude, roll: roll);
  }

  Vector3 _directionThroughScreenPoint(Offset screenPos) {
    final xScreen = screenPos.dx - (viewportSize.width / 2.0);
    final yScreen = (viewportSize.height / 2.0) - screenPos.dy;

    final ray =
        (_forwardVector * _focalLength) +
        (_rightVector * xScreen) +
        (_upVector * yScreen);
    return ray.normalized();
  }
}
