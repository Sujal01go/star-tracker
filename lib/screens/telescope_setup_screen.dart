import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../sensors/device_orientation_service.dart';
import '../sensors/heading_calibration.dart';

/// Phone-based instruments and a short checklist for setting up a telescope.
class TelescopeSetupScreen extends StatefulWidget {
  final DeviceOrientationService orientationService;
  final bool isActive;

  const TelescopeSetupScreen({
    super.key,
    required this.orientationService,
    this.isActive = false,
  });

  @override
  State<TelescopeSetupScreen> createState() => _TelescopeSetupScreenState();
}

class _TelescopeSetupScreenState extends State<TelescopeSetupScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) _scheduleSensorResume();
  }

  @override
  void didUpdateWidget(covariant TelescopeSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _scheduleSensorResume();
  }

  void _scheduleSensorResume() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) _resumeSensors();
    });
  }

  void _resumeSensors() {
    widget.orientationService.start();
    widget.orientationService.setTracking(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.orientationService,
      builder: (context, _) {
        final orientationService = widget.orientationService;
        final heading = orientationService.compassAzimuth;
        final levelPitch = orientationService.levelPitch;
        final levelRoll = orientationService.levelRoll;
        final level = levelPitch.abs() <= 1.5 && levelRoll.abs() <= 1.5;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Align your mount',
                              style: TextStyle(
                                color: AstroTrackColors.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SensorStatus(
                        hasSensors: orientationService.hasSensors,
                        tracking: orientationService.isTrackingActive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CompassInstrument(
                          heading: heading,
                          accuracy: orientationService.calibration.accuracy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LevelInstrument(
                          pitch: levelPitch,
                          roll: levelRoll,
                          isLevel: level,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 28),
                  const Text(
                    'Before you observe',
                    style: TextStyle(
                      color: AstroTrackColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const _SetupStep(
                    number: '01',
                    icon: Icons.foundation_outlined,
                    title: 'Level the tripod',
                    detail: 'Set up on firm ground and level the mount base.',
                  ),
                  const _SetupStep(
                    number: '02',
                    icon: Icons.explore_outlined,
                    title: 'Point the mount north',
                    detail:
                        'Take a compass reading away from metal, then account for local magnetic declination.',
                  ),
                  const _SetupStep(
                    number: '03',
                    icon: Icons.center_focus_weak,
                    title: 'Align the finder',
                    detail:
                        'Center a distant object in the eyepiece and finder.',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'For the level, place the phone screen-up with its long edge parallel to the tube. Metal mounts can distort the compass, so check north a short distance away. Use the mount’s alignment procedure for precision.',
                    style: TextStyle(
                      color: AstroTrackColors.textMuted,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SensorStatus extends StatelessWidget {
  final bool hasSensors;
  final bool tracking;

  const _SensorStatus({required this.hasSensors, required this.tracking});

  @override
  Widget build(BuildContext context) {
    final color = !hasSensors
        ? AstroTrackColors.danger
        : tracking
        ? AstroTrackColors.accent
        : AstroTrackColors.warm;
    final label = !hasSensors
        ? 'No sensors'
        : tracking
        ? 'Tracking'
        : 'Paused';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !hasSensors
                ? Icons.sensors_off
                : tracking
                ? Icons.sensors
                : Icons.pause_circle_outline,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrumentFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _InstrumentFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
      decoration: BoxDecoration(
        color: AstroTrackColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AstroTrackColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AstroTrackColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CompassInstrument extends StatelessWidget {
  final double heading;
  final SensorAccuracy accuracy;

  const _CompassInstrument({required this.heading, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final cardinal = _cardinalDirection(heading);
    return _InstrumentFrame(
      title: 'Compass',
      child: Column(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _CompassPainter(heading: heading),
              child: Center(
                child: Text(
                  cardinal,
                  style: const TextStyle(
                    color: AstroTrackColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${heading.round() % 360}°',
            style: const TextStyle(
              color: AstroTrackColors.accent,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Magnetic · ${_accuracyLabel(accuracy)} accuracy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AstroTrackColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _accuracyLabel(SensorAccuracy accuracy) => switch (accuracy) {
  SensorAccuracy.high => 'good',
  SensorAccuracy.medium => 'fair',
  SensorAccuracy.low => 'low',
  SensorAccuracy.unreliable => 'unreliable',
};

String _cardinalDirection(double heading) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return directions[((heading / 45).round() % 8)];
}

class _CompassPainter extends CustomPainter {
  final double heading;

  const _CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final ring = Paint()
      ..color = AstroTrackColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, ring);
    final tick = Paint()
      ..color = AstroTrackColors.textMuted
      ..strokeWidth = 1.2;
    for (var i = 0; i < 36; i++) {
      final angle = (i * 10 - heading - 90) * math.pi / 180;
      final major = i % 9 == 0;
      final inner = radius - (major ? 9 : 4);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * inner,
          center.dy + math.sin(angle) * inner,
        ),
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        tick,
      );
    }
    final north = Paint()
      ..color = AstroTrackColors.accent
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius + 6)
      ..lineTo(center.dx - 5, center.dy - 1)
      ..lineTo(center.dx + 5, center.dy - 1)
      ..close();
    canvas.drawPath(path, north);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.heading != heading;
}

class _LevelInstrument extends StatelessWidget {
  final double pitch;
  final double roll;
  final bool isLevel;

  const _LevelInstrument({
    required this.pitch,
    required this.roll,
    required this.isLevel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLevel ? AstroTrackColors.accent : AstroTrackColors.warm;
    return _InstrumentFrame(
      title: 'Level',
      child: Column(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _BubbleLevelPainter(
                pitch: pitch,
                roll: roll,
                color: color,
              ),
              child: Center(
                child: Icon(
                  isLevel ? Icons.check : Icons.circle,
                  size: isLevel ? 18 : 7,
                  color: isLevel ? color : AstroTrackColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLevel ? 'Level' : 'Adjust',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'P ${_signedDegrees(pitch)}  R ${_signedDegrees(roll)}',
            maxLines: 1,
            style: const TextStyle(
              color: AstroTrackColors.textSecondary,
              fontSize: 9,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _signedDegrees(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}°';

class _BubbleLevelPainter extends CustomPainter {
  final double pitch;
  final double roll;
  final Color color;

  const _BubbleLevelPainter({
    required this.pitch,
    required this.roll,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final ring = Paint()
      ..color = AstroTrackColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.58, ring);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ring,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ring,
    );
    final dx = (roll / 8).clamp(-1.0, 1.0) * radius * 0.68;
    final dy = (pitch / 8).clamp(-1.0, 1.0) * radius * 0.68;
    canvas.drawCircle(
      center + Offset(dx, dy),
      6,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center + Offset(dx, dy), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleLevelPainter oldDelegate) =>
      oldDelegate.pitch != pitch ||
      oldDelegate.roll != roll ||
      oldDelegate.color != color;
}

class _SetupStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String detail;

  const _SetupStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              number,
              style: const TextStyle(
                color: AstroTrackColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(icon, size: 18, color: AstroTrackColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AstroTrackColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AstroTrackColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
