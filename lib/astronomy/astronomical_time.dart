/// Astronomical time calculations: Julian Date, Julian Ephemeris Century, and calendar transformations.
class AstronomicalTime {
  /// Standard J2000.0 epoch in Julian Date (2000-01-01 12:00:00 UTC).
  static const double j2000Epoch = 2451545.0;

  /// Standard days per Julian century.
  static const double daysPerJulianCentury = 36525.0;

  /// Computes the Julian Date (JD) for a given [DateTime] in UTC.
  /// Uses the rigorous Meeus algorithm (valid for all Gregorian dates).
  static double julianDate(DateTime utcDateTime) {
    final utc = utcDateTime.toUtc();
    int year = utc.year;
    int month = utc.month;
    final double dayFraction =
        utc.day +
        (utc.hour +
                (utc.minute +
                        (utc.second +
                                utc.millisecond / 1000.0 +
                                utc.microsecond / 1000000.0) /
                            60.0) /
                    60.0) /
            24.0;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final int a = (year / 100).floor();
    final int b = 2 - a + (a / 4).floor();

    final double jd =
        (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        dayFraction +
        b -
        1524.5;

    return jd;
  }

  /// Computes the number of Julian centuries $T$ elapsed since the J2000.0 epoch:
  /// $T = (JD - 2451545.0) / 36525.0$
  static double julianCenturiesJ2000(double jd) {
    return (jd - j2000Epoch) / daysPerJulianCentury;
  }

  /// Computes the [DateTime] (in UTC) corresponding to a given Julian Date [jd].
  static DateTime dateTimeFromJulianDate(double jd) {
    final double z = (jd + 0.5).floorToDouble();
    final double f = (jd + 0.5) - z;

    double a = z;
    if (z >= 2299161.0) {
      final double alpha = ((z - 1867216.25) / 36524.25).floorToDouble();
      a = z + 1.0 + alpha - (alpha / 4.0).floorToDouble();
    }

    final double b = a + 1524.0;
    final double c = ((b - 122.1) / 365.25).floorToDouble();
    final double d = (365.25 * c).floorToDouble();
    final double e = ((b - d) / 30.6001).floorToDouble();

    final double dayFraction = b - d - (30.6001 * e).floorToDouble() + f;
    final int day = dayFraction.floor();

    int month;
    if (e < 14.0) {
      month = (e - 1.0).toInt();
    } else {
      month = (e - 13.0).toInt();
    }

    int year;
    if (month > 2) {
      year = (c - 4716.0).toInt();
    } else {
      year = (c - 4715.0).toInt();
    }

    final double fractionOfDay = dayFraction - day;
    final double hoursTotal = fractionOfDay * 24.0;
    final int hour = hoursTotal.floor();
    final double minutesTotal = (hoursTotal - hour) * 60.0;
    final int minute = minutesTotal.floor();
    final double secondsTotal = (minutesTotal - minute) * 60.0;
    final int second = secondsTotal.floor();
    final int millisecond = ((secondsTotal - second) * 1000.0).round();

    return DateTime.utc(year, month, day, hour, minute, second, millisecond);
  }
}
