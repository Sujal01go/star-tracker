import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/sensors/device_orientation_service.dart';

void main() {
  group('DeviceOrientationService Pitch & Elevation Tests', () {
    late DeviceOrientationService service;

    setUp(() {
      service = DeviceOrientationService();
    });

    test('Initial altitude starts at comfortable 35° stargazing angle', () {
      expect(service.altitude, closeTo(35.0, 0.1));
      expect(service.invertPitch, isFalse);
    });

    test(
      'Holding phone vertical towards horizon (y ≈ 9.8, z ≈ 0) gives ~0° altitude',
      () {
        // Simulate vertical phone (horizon gaze)
        for (int i = 0; i < 30; i++) {
          service.processAccelerometerData(0.0, 9.81, 0.0);
        }
        expect(service.altitude, closeTo(0.0, 1.0));
      },
    );

    test(
      'Tilting phone UPWARD towards Zenith (z < 0) increases altitude to +90°',
      () {
        // Tilting phone up to point camera (-Z) at zenith means screen (+Z) faces down: z = -9.81
        for (int i = 0; i < 30; i++) {
          service.processAccelerometerData(0.0, 0.0, -9.81);
        }
        expect(service.altitude, closeTo(90.0, 1.0));
      },
    );

    test(
      'Tilting phone DOWNWARD towards Nadir (z > 0) decreases altitude to -90°',
      () {
        // Tilting phone down to point camera (-Z) at ground means screen (+Z) faces up: z = +9.81
        for (int i = 0; i < 30; i++) {
          service.processAccelerometerData(0.0, 0.0, 9.81);
        }
        expect(service.altitude, closeTo(-90.0, 1.0));
      },
    );

    test('Tilting phone 45° upward gives positive altitude ~45°', () {
      // 45° elevation: y = 9.81 * cos(45°), z = -9.81 * sin(45°)
      const double comp = 6.936; // 9.81 / sqrt(2)
      for (int i = 0; i < 30; i++) {
        service.processAccelerometerData(0.0, comp, -comp);
      }
      expect(service.altitude, closeTo(45.0, 1.5));
    });

    test('Flat-mounted setup level is zero on a level surface', () {
      service.processAccelerometerData(0.0, 0.0, 9.81);

      expect(service.levelPitch, closeTo(0.0, 0.1));
      expect(service.levelRoll, closeTo(0.0, 0.1));
    });

    test('Flat-mounted setup level reads both tilt axes', () {
      const double comp = 6.936;
      for (int i = 0; i < 30; i++) {
        service.processAccelerometerData(0.0, comp, comp);
      }
      expect(service.levelPitch, closeTo(45.0, 1.0));
      expect(service.levelRoll, closeTo(0.0, 0.1));

      final crossAxisService = DeviceOrientationService();
      for (int i = 0; i < 30; i++) {
        crossAxisService.processAccelerometerData(-comp, 0.0, comp);
      }
      expect(crossAxisService.levelPitch, closeTo(0.0, 0.1));
      expect(crossAxisService.levelRoll, closeTo(45.0, 1.0));
    });

    test('Inverting pitch inverts the altitude response', () {
      service.setInvertPitch(true);
      expect(service.invertPitch, isTrue);

      // With inverted pitch, z = -9.81 (pointing up) yields -90°
      for (int i = 0; i < 30; i++) {
        service.processAccelerometerData(0.0, 0.0, -9.81, deltaSeconds: 0.1);
      }
      expect(service.altitude, closeTo(-90.0, 1.0));

      // And z = +9.81 yields +90°
      for (int i = 0; i < 30; i++) {
        service.processAccelerometerData(0.0, 0.0, 9.81, deltaSeconds: 0.1);
      }
      expect(service.altitude, closeTo(90.0, 1.0));
    });

    test('Heading calibration and nudging adjusts azimuth immediately', () {
      expect(service.calibration.manualHeadingOffset, 0.0);

      // Nudge heading by -4.5 degrees
      service.nudgeHeadingOffset(-4.5);
      expect(service.calibration.manualHeadingOffset, closeTo(-4.5, 0.01));

      // Nudge again by +1.0 degree
      service.nudgeHeadingOffset(1.0);
      expect(service.calibration.manualHeadingOffset, closeTo(-3.5, 0.01));

      // Reset to 0
      service.setManualCalibrationOffset(0.0);
      expect(service.calibration.manualHeadingOffset, 0.0);
    });

    test('Telescope compass ignores saved sky-map heading trim', () {
      service.setManualCalibrationOffset(180.0);
      service.processCompassData(0.0, accuracy: 15.0);

      expect(service.azimuth, closeTo(180.0, 0.01));
      expect(service.compassAzimuth, closeTo(0.0, 0.01));
    });
  });
}
