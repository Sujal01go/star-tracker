import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/observer_location.dart';

/// Result wrapper for location requests to ensure zero crashes on permission denial or service issues.
class LocationResult {
  final ObserverLocation? location;
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isServiceDisabled;

  const LocationResult({
    this.location,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isServiceDisabled = false,
  });

  bool get isSuccess => location != null;
}

/// Service managing device GPS location and manual coordinate overrides.
class LocationService {
  /// Fetches the observer's current geographic coordinates via GPS.
  /// Handles permission checks, service availability, and denials safely without throwing uncaught exceptions.
  static Future<LocationResult> getCurrentGpsLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          errorMessage:
              'Location services are disabled on this device. Please enable GPS in system settings.',
          isServiceDisabled: true,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            errorMessage:
                'Location permission was denied. You can manually enter your coordinates.',
            isPermissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          errorMessage:
              'Location permissions are permanently denied. Please grant permission in App Settings or enter coordinates manually.',
          isPermissionDenied: true,
        );
      }

      // Permissions granted: retrieve current fix
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final obsLocation = ObserverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        altitudeMeters: position.altitude,
        name:
            'GPS (${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°)',
      );

      return LocationResult(location: obsLocation);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return LocationResult(
        errorMessage: 'Failed to acquire GPS fix: ${e.toString()}',
      );
    }
  }
}
