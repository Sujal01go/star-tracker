import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../models/observer_location.dart';
import '../rendering/star_rendering_style.dart';
import '../sensors/device_orientation_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';

/// Application configuration and astronomical settings screen.
class SettingsScreen extends StatefulWidget {
  final AstronomyEngine astronomyEngine;
  final DeviceOrientationService orientationService;
  final StarRenderingStyle style;
  final PreferencesService? preferencesService;
  final ValueChanged<StarRenderingStyle> onStyleChanged;

  const SettingsScreen({
    super.key,
    required this.astronomyEngine,
    required this.orientationService,
    required this.style,
    this.preferencesService,
    required this.onStyleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StarRenderingStyle _style;
  bool _isLocatingGps = false;

  @override
  void initState() {
    super.initState();
    _style = widget.style;
  }

  void _updateStyle(StarRenderingStyle newStyle) {
    setState(() {
      _style = newStyle;
    });
    widget.onStyleChanged(newStyle);
    widget.preferencesService?.saveRenderingStyle(newStyle);
  }

  Future<void> _fetchGpsLocation() async {
    setState(() => _isLocatingGps = true);
    final result = await LocationService.getCurrentGpsLocation();
    setState(() => _isLocatingGps = false);

    if (!mounted) return;

    if (result.isSuccess) {
      widget.astronomyEngine.updateLocation(result.location!);
      widget.preferencesService?.saveLocation(result.location!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated observer location to ${result.location!.name}',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Unable to get GPS location'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showManualLocationDialog() async {
    final latCtrl = TextEditingController(
      text: widget.astronomyEngine.location.latitude.toString(),
    );
    final lonCtrl = TextEditingController(
      text: widget.astronomyEngine.location.longitude.toString(),
    );
    final altCtrl = TextEditingController(
      text: widget.astronomyEngine.location.altitudeMeters.toString(),
    );
    final nameCtrl = TextEditingController(
      text: widget.astronomyEngine.location.name,
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _style.nightMode
              ? const Color(0xFF1E0505)
              : AstroTrackColors.surface,
          title: Text(
            'Manual Observer Coordinates',
            style: TextStyle(color: _style.textColor, fontSize: 16.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: _style.textColor),
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    labelStyle: TextStyle(color: _style.secondaryTextColor),
                  ),
                ),
                TextField(
                  controller: latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  style: TextStyle(color: _style.textColor),
                  decoration: InputDecoration(
                    labelText: 'Latitude (-90 to +90 deg, North +)',
                    labelStyle: TextStyle(color: _style.secondaryTextColor),
                  ),
                ),
                TextField(
                  controller: lonCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  style: TextStyle(color: _style.textColor),
                  decoration: InputDecoration(
                    labelText: 'Longitude (-180 to +180 deg, East +)',
                    labelStyle: TextStyle(color: _style.secondaryTextColor),
                  ),
                ),
                TextField(
                  controller: altCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: _style.textColor),
                  decoration: InputDecoration(
                    labelText: 'Elevation (meters above sea level)',
                    labelStyle: TextStyle(color: _style.secondaryTextColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: _style.secondaryTextColor),
              ),
            ),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(latCtrl.text);
                final lon = double.tryParse(lonCtrl.text);
                final alt = double.tryParse(altCtrl.text) ?? 0.0;
                final name = nameCtrl.text.trim().isNotEmpty
                    ? nameCtrl.text.trim()
                    : 'Custom Location';

                if (lat != null &&
                    lon != null &&
                    lat >= -90.0 &&
                    lat <= 90.0 &&
                    lon >= -180.0 &&
                    lon <= 180.0) {
                  final newLoc = ObserverLocation(
                    latitude: lat,
                    longitude: lon,
                    altitudeMeters: alt,
                    name: name,
                  );
                  widget.astronomyEngine.updateLocation(newLoc);
                  widget.preferencesService?.saveLocation(newLoc);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _style.nightMode;
    final bgColor = isNight
        ? const Color(0xFF0F0202)
        : AstroTrackColors.background;
    final cardBg = isNight ? const Color(0xFF1B0404) : AstroTrackColors.surface;
    final borderColor = isNight
        ? const Color(0x55FF3333)
        : AstroTrackColors.line;
    final textPrimary = _style.textColor;
    final textSecondary = _style.secondaryTextColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Settings & Calibration',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. OBSERVER LOCATION
          _sectionTitle('OBSERVER LOCATION', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.my_location, color: accent),
                  title: Text(
                    widget.astronomyEngine.location.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${widget.astronomyEngine.location.latitude.toStringAsFixed(2)}° Lat, ${widget.astronomyEngine.location.longitude.toStringAsFixed(2)}° Lon (${widget.astronomyEngine.location.altitudeMeters.toStringAsFixed(0)}m)',
                    style: TextStyle(color: textSecondary, fontSize: 12.0),
                  ),
                  trailing: _isLocatingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.gps_fixed, color: accent),
                          tooltip: 'Detect via GPS',
                          onPressed: _fetchGpsLocation,
                        ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: Icon(
                    Icons.edit_location_alt_outlined,
                    color: textSecondary,
                  ),
                  title: Text(
                    'Enter Custom Coordinates',
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: _showManualLocationDialog,
                ),
                const Divider(height: 1, color: Colors.white10),
                // Location presets dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: DropdownButtonFormField<ObserverLocation>(
                    dropdownColor: cardBg,
                    decoration: InputDecoration(
                      labelText: 'Select Global Observatory Preset',
                      labelStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 12.0,
                      ),
                      border: InputBorder.none,
                    ),
                    items: ObserverLocation.presets.map((preset) {
                      return DropdownMenuItem<ObserverLocation>(
                        value: preset,
                        child: Text(
                          preset.name,
                          style: TextStyle(color: textPrimary, fontSize: 13.0),
                        ),
                      );
                    }).toList(),
                    onChanged: (loc) {
                      if (loc != null) {
                        widget.astronomyEngine.updateLocation(loc);
                        widget.preferencesService?.saveLocation(loc);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. DISPLAY & VISUALS
          _sectionTitle('DISPLAY & NIGHT VISION', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.nightlight_round,
                    color: isNight ? Colors.redAccent : textSecondary,
                  ),
                  title: Text(
                    'Red Night-Vision Mode',
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    'Preserves dark adaptation in field observations',
                    style: TextStyle(color: textSecondary, fontSize: 12.0),
                  ),
                  value: _style.nightMode,
                  activeThumbColor: Colors.redAccent,
                  onChanged: (v) => _updateStyle(_style.copyWith(nightMode: v)),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  secondary: Icon(Icons.hub_outlined, color: textSecondary),
                  title: Text(
                    'Constellation Lines',
                    style: TextStyle(color: textPrimary),
                  ),
                  value: _style.showConstellationLines,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      _updateStyle(_style.copyWith(showConstellationLines: v)),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  secondary: Icon(Icons.title, color: textSecondary),
                  title: Text(
                    'Constellation Names',
                    style: TextStyle(color: textPrimary),
                  ),
                  value: _style.showConstellationNames,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      _updateStyle(_style.copyWith(showConstellationNames: v)),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  secondary: Icon(Icons.grid_4x4, color: textSecondary),
                  title: Text(
                    'Celestial Grid',
                    style: TextStyle(color: textPrimary),
                  ),
                  value: _style.showCelestialGrid,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      _updateStyle(_style.copyWith(showCelestialGrid: v)),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  secondary: Icon(Icons.label_outline, color: textSecondary),
                  title: Text(
                    'Star Names & Labels',
                    style: TextStyle(color: textPrimary),
                  ),
                  value: _style.showStarLabels,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      _updateStyle(_style.copyWith(showStarLabels: v)),
                ),
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Limiting Magnitude: ${_style.limitingMagnitude.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _style.limitingMagnitude,
                        min: 1.0,
                        max: 7.0,
                        divisions: 24,
                        activeColor: accent,
                        onChanged: (v) =>
                            _updateStyle(_style.copyWith(limitingMagnitude: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. COMPASS & ORIENTATION CALIBRATION
          _sectionTitle(
            'SENSOR ORIENTATION & HEADING CALIBRATION',
            textSecondary,
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Heading Offset: ${widget.orientationService.calibration.manualHeadingOffset >= 0 ? "+" : ""}${widget.orientationService.calibration.manualHeadingOffset.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Adjust this offset to compensate for local magnetic declination or phone casing bias. If stars appear shifted 4°–5° to the left (anticlockwise), nudge by -4° to -5°.',
                  style: TextStyle(color: textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _headingNudgeButton('-5°', -5.0, accent, textPrimary),
                    _headingNudgeButton('-1°', -1.0, accent, textPrimary),
                    _headingResetButton('0° Reset', accent, textPrimary),
                    _headingNudgeButton('+1°', 1.0, accent, textPrimary),
                    _headingNudgeButton('+5°', 5.0, accent, textPrimary),
                  ],
                ),
                Slider(
                  value:
                      widget.orientationService.calibration.manualHeadingOffset,
                  min: -180.0,
                  max: 180.0,
                  divisions: 720,
                  activeColor: accent,
                  onChanged: (v) {
                    setState(() {
                      widget.orientationService.setManualCalibrationOffset(v);
                    });
                    widget.preferencesService?.saveHeadingOffset(v);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To calibrate physical magnetometer, move your phone in a slow figure-8 motion.',
                        style: TextStyle(color: textSecondary, fontSize: 11.0),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Invert Vertical Axis (Pitch)',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Inverts the vertical tracking direction when tilting or panning.',
                    style: TextStyle(color: textSecondary, fontSize: 11.5),
                  ),
                  value: widget.orientationService.invertPitch,
                  activeThumbColor: accent,
                  onChanged: (v) {
                    setState(() {
                      widget.orientationService.setInvertPitch(v);
                    });
                    widget.preferencesService?.saveInvertPitch(v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. ASTRONOMICAL CORRECTIONS
          _sectionTitle('ASTRONOMICAL ENGINE PRECISION', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'IAU Precession (J2000.0 to Date)',
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    'Accounts for axial precession across epochs',
                    style: TextStyle(color: textSecondary, fontSize: 12.0),
                  ),
                  value: widget.astronomyEngine.applyPrecession,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      widget.astronomyEngine.setPrecessionEnabled(v),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(
                    'Atmospheric Refraction',
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    'Bennett formula elevation correction near horizon',
                    style: TextStyle(color: textSecondary, fontSize: 12.0),
                  ),
                  value: widget.astronomyEngine.applyRefraction,
                  activeThumbColor: accent,
                  onChanged: (v) =>
                      widget.astronomyEngine.setRefractionEnabled(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT & ATTRIBUTION
          Center(
            child: Column(
              children: [
                Text(
                  'AstroTrack v1.0.0',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline Astronomical Engine • Hipparcos / BSC5 Catalogue Data',
                  style: TextStyle(color: textSecondary, fontSize: 11.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _headingNudgeButton(
    String label,
    double delta,
    Color accent,
    Color textPrimary,
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
        setState(() {
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

  Widget _headingResetButton(String label, Color accent, Color textPrimary) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        minimumSize: const Size(60, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: () {
        setState(() {
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
}
