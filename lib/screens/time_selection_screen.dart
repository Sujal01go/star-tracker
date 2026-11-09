import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../astronomy/astronomical_time.dart';
import '../astronomy/sidereal_time.dart';
import '../models/observation_time.dart';
import '../rendering/star_rendering_style.dart';

/// Screen allowing manual selection of observation time and date.
class TimeSelectionScreen extends StatefulWidget {
  final ObservationTime initialTime;
  final StarRenderingStyle style;
  final ValueChanged<ObservationTime> onTimeChanged;

  const TimeSelectionScreen({
    super.key,
    required this.initialTime,
    required this.style,
    required this.onTimeChanged,
  });

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  late DateTime _selectedUtcTime;
  late bool _isRealTime;
  late double _speedMultiplier;

  @override
  void initState() {
    super.initState();
    _selectedUtcTime = widget.initialTime.utcDateTime;
    _isRealTime = widget.initialTime.isRealTime;
    _speedMultiplier = widget.initialTime.speedMultiplier;
  }

  void _applyChange() {
    widget.onTimeChanged(
      ObservationTime(
        utcDateTime: _selectedUtcTime,
        isRealTime: _isRealTime,
        speedMultiplier: _speedMultiplier,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedUtcTime.toLocal(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _isRealTime = false;
        final local = _selectedUtcTime.toLocal();
        final newLocal = DateTime(
          picked.year,
          picked.month,
          picked.day,
          local.hour,
          local.minute,
          local.second,
        );
        _selectedUtcTime = newLocal.toUtc();
        _applyChange();
      });
    }
  }

  Future<void> _pickTime() async {
    final local = _selectedUtcTime.toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (picked != null) {
      setState(() {
        _isRealTime = false;
        final newLocal = DateTime(
          local.year,
          local.month,
          local.day,
          picked.hour,
          picked.minute,
          local.second,
        );
        _selectedUtcTime = newLocal.toUtc();
        _applyChange();
      });
    }
  }

  void _adjustHours(int delta) {
    setState(() {
      _isRealTime = false;
      _selectedUtcTime = _selectedUtcTime.add(Duration(hours: delta));
      _applyChange();
    });
  }

  void _adjustDays(int delta) {
    setState(() {
      _isRealTime = false;
      _selectedUtcTime = _selectedUtcTime.add(Duration(days: delta));
      _applyChange();
    });
  }

  void _setNow() {
    setState(() {
      _isRealTime = true;
      _selectedUtcTime = DateTime.now().toUtc();
      _applyChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.style.nightMode;
    final bgColor = isNight
        ? const Color(0xFF0F0202)
        : AstroTrackColors.background;
    final cardBg = isNight ? const Color(0xFF1B0404) : AstroTrackColors.surface;
    final borderColor = isNight
        ? const Color(0x55FF3333)
        : AstroTrackColors.line;
    final textPrimary = widget.style.textColor;
    final textSecondary = widget.style.secondaryTextColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    final jd = AstronomicalTime.julianDate(_selectedUtcTime);
    final gmst = SiderealTime.greenwichMeanSiderealTime(jd);
    final localTime = _selectedUtcTime.toLocal();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Observation Time',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live time mode toggle
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: borderColor),
              ),
              child: SwitchListTile(
                title: Text(
                  'Live System Clock',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Continuously sync with current system time',
                  style: TextStyle(color: textSecondary, fontSize: 12.0),
                ),
                activeThumbColor: accent,
                value: _isRealTime,
                onChanged: (val) {
                  setState(() {
                    _isRealTime = val;
                    if (val) _selectedUtcTime = DateTime.now().toUtc();
                    _applyChange();
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time Display & Pickers
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: accent,
                          ),
                          label: Text(
                            '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}',
                            style: TextStyle(color: textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.access_time,
                            size: 16,
                            color: accent,
                          ),
                          label: Text(
                            '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}',
                            style: TextStyle(color: textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'UTC: ${_selectedUtcTime.toIso8601String().substring(0, 19).replaceAll('T', ' ')}Z',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fast Step Adjustment Controls
            Text(
              'FAST TIME STEPPING',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _stepButton(
                  '-1 Day',
                  () => _adjustDays(-1),
                  cardBg,
                  borderColor,
                  textPrimary,
                ),
                _stepButton(
                  '-1 Hour',
                  () => _adjustHours(-1),
                  cardBg,
                  borderColor,
                  textPrimary,
                ),
                _stepButton('Now', _setNow, cardBg, accent, accent),
                _stepButton(
                  '+1 Hour',
                  () => _adjustHours(1),
                  cardBg,
                  borderColor,
                  textPrimary,
                ),
                _stepButton(
                  '+1 Day',
                  () => _adjustDays(1),
                  cardBg,
                  borderColor,
                  textPrimary,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Astronomical Ephemeris Time Diagnostics
            Text(
              'ASTRONOMICAL TIME COMPUTATION',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _diagRow(
                    'Julian Date (JD)',
                    jd.toStringAsFixed(5),
                    textPrimary,
                    textSecondary,
                  ),
                  const Divider(color: Colors.white10),
                  _diagRow(
                    'Centuries from J2000.0 (T)',
                    AstronomicalTime.julianCenturiesJ2000(
                      jd,
                    ).toStringAsFixed(6),
                    textPrimary,
                    textSecondary,
                  ),
                  const Divider(color: Colors.white10),
                  _diagRow(
                    'Greenwich Sidereal Time (GMST)',
                    '${gmst.toStringAsFixed(2)}° (${(gmst / 15.0).toStringAsFixed(2)}h)',
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton(
    String label,
    VoidCallback onPressed,
    Color bg,
    Color border,
    Color text,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _diagRow(
    String label,
    String value,
    Color primaryColor,
    Color subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subColor, fontSize: 12.0)),
          Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: 12.0,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
