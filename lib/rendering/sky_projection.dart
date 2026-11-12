import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../astronomy/spherical_geometry.dart';
import '../models/sky_position.dart';

/// Projects fixed directions on the celestial sphere onto the observer's view.
///
/// Angular distance from the view direction maps linearly to screen distance,
/// which avoids the severe stretching near the edge of a pinhole projection.
/// The camera itself remains a 3D trackball, so the sky moves as one sphere.
class SkyProjection {
  static final Expando<Vector3> _skyDirectionCache = Expando<Vector3>(
    'sky map unit direction',
  );

  final double centerAzimuth;
  final double centerAltitude;
  final double rollAngle;
  final double fieldOfView;
  final Size viewportSize;

  late final Vector3 _forwardVector;
  late final Vector3 _rightVector;
  late final Vector3 _upVector;
  late final double _pixelsPerRadian;

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
    // Topocentric axes: X = East, Y = North, Z = Zenith.
    _forwardVector = SphericalGeometry.horizontalToUnitVector(
      centerAzimuth,
      centerAltitude,
    ).normalized();

    // Keep a stable horizon basis at both poles. The view's azimuth supplies
    // the otherwise undefined direction at zenith and nadir.
    final azimuthRadians = SphericalGeometry.toRadians(centerAzimuth);
    var right = Vector3(
      math.cos(azimuthRadians),
      -math.sin(azimuthRadians),
      0.0,
    ).normalized();
    var up = right.cross(_forwardVector).normalized();

    if (rollAngle.abs() > 0.001) {
      final rollRadians = SphericalGeometry.toRadians(rollAngle);
      final cosRoll = math.cos(rollRadians);
      final sinRoll = math.sin(rollRadians);
      final rolledRight = (right * cosRoll) + (up * sinRoll);
      final rolledUp = (up * cosRoll) - (right * sinRoll);
      right = rolledRight.normalized();
      up = rolledUp.normalized();
    }

    _rightVector = right;
    _upVector = up;

    // Keep the existing FOV convention: the smaller viewport dimension spans
    // the requested field of view. Clamp malformed values away from singulars.
    final safeFov = fieldOfView.clamp(1.0, 179.0);
    final halfFovRadians = SphericalGeometry.toRadians(safeFov / 2.0);
    final minDimension = math.min(viewportSize.width, viewportSize.height);
    _pixelsPerRadian = minDimension / (2.0 * halfFovRadians);
  }

  /// Projects a horizontal sky coordinate (azimuth, altitude) onto screen.
  /// Returns `null` when the direction is outside the visible viewport margin.
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
    ).normalized();
    return _projectDirection(direction);
  }

  Offset? _projectDirection(Vector3 direction) {
    final xCamera = direction.dot(_rightVector);
    final yCamera = direction.dot(_upVector);
    final zCamera = direction.dot(_forwardVector).clamp(-1.0, 1.0);
    final sinTheta = math.sqrt(xCamera * xCamera + yCamera * yCamera);

    double xScreenOffset;
    double yScreenOffset;
    if (sinTheta < 1e-9) {
      if (zCamera >= 0.0) {
        xScreenOffset = 0.0;
        yScreenOffset = 0.0;
      } else {
        // The antipode has no unique bearing. Give it a stable seam direction;
        // with the app's FOV it will be outside the viewport in normal use.
        xScreenOffset = math.pi * _pixelsPerRadian;
        yScreenOffset = 0.0;
      }
    } else {
      final angularDistance = math.atan2(sinTheta, zCamera);
      final radialDistance = angularDistance * _pixelsPerRadian;
      xScreenOffset = radialDistance * (xCamera / sinTheta);
      yScreenOffset = radialDistance * (yCamera / sinTheta);
    }

    final xScreen = (viewportSize.width / 2.0) + xScreenOffset;
    final yScreen = (viewportSize.height / 2.0) - yScreenOffset;

    const margin = 80.0;
    if (xScreen < -margin ||
        xScreen > viewportSize.width + margin ||
        yScreen < -margin ||
        yScreen > viewportSize.height + margin) {
      return null;
    }

    return Offset(xScreen, yScreen);
  }

  /// Converts a screen point back to its direction on the celestial sphere.
  SkyPosition? unprojectScreenCoordinates(Offset screenPos) {
    final direction = _directionThroughScreenPoint(screenPos);
    final horizontal = SphericalGeometry.unitVectorToHorizontal(direction);
    return SkyPosition(
      azimuth: horizontal.azimuth,
      altitude: horizontal.altitude,
    );
  }

  /// Rotates the camera in 3D so the sky point under [previousPosition]
  /// follows the finger to [currentPosition].
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
    final horizontalLength = math.sqrt(
      forward.x * forward.x + forward.y * forward.y,
    );
    final azimuth = horizontalLength > 1e-6
        ? SphericalGeometry.normalizeDegrees360(
            SphericalGeometry.toDegrees(math.atan2(forward.x, forward.y)),
          )
        : centerAzimuth;
    final altitude = SphericalGeometry.toDegrees(
      math.atan2(forward.z, horizontalLength),
    );

    // Reconstruct roll against a stable local horizon frame on both poles.
    final azimuthRadians = SphericalGeometry.toRadians(azimuth);
    final horizonRight = Vector3(
      math.cos(azimuthRadians),
      -math.sin(azimuthRadians),
      0.0,
    ).normalized();
    final horizonUp = horizonRight.cross(forward).normalized();
    final roll = SphericalGeometry.toDegrees(
      math.atan2(right.dot(horizonUp), right.dot(horizonRight)),
    );

    return (azimuth: azimuth, altitude: altitude, roll: roll);
  }

  Vector3 _directionThroughScreenPoint(Offset screenPos) {
    final xScreen = screenPos.dx - (viewportSize.width / 2.0);
    final yScreen = (viewportSize.height / 2.0) - screenPos.dy;
    final radius = math.sqrt(xScreen * xScreen + yScreen * yScreen);

    if (radius < 1e-9) return _forwardVector.clone();

    final angularDistance = radius / _pixelsPerRadian;
    final sinTheta = math.sin(angularDistance);
    final cosTheta = math.cos(angularDistance);
    final xBearing = xScreen / radius;
    final yBearing = yScreen / radius;

    return ((_forwardVector * cosTheta) +
            (_rightVector * (xBearing * sinTheta)) +
            (_upVector * (yBearing * sinTheta)))
        .normalized();
  }
}
