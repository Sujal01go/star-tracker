# AstroTrack — Offline-First Flutter Star Tracker

**AstroTrack** is an accurate, offline-first mobile astronomy application built with Flutter and Dart for Android. It renders real-time interactive night sky maps using authentic astronomical catalogue data (Hipparcos & Yale Bright Star Catalogue), mathematically rigorous coordinate transformations, spherical perspective projection, and device sensor orientation tracking (AR compass mode).

---

## 1. Key Features

- **Accurate Mathematical Astronomy Engine**: Computes exact topocentric horizontal coordinates (Azimuth and Altitude) from J2000.0 Right Ascension and Declination for any terrestrial latitude, longitude, and UTC timestamp.
- **Dynamic Planetary Ephemerides**: Implements NASA JPL Keplerian orbital elements (Standish 1992) and Meeus analytical perturbations for all 8 major planets (Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune), the Sun, and the Moon with real-time phase angles, distance in AU/million km, and illumination fractions.
- **All 88 Official IAU Constellations**: Complete dataset covering all 88 modern constellations with authentic star-pair asterism connections across northern and southern celestial hemispheres.
- **Offline-First Real Astronomical Data**: Integrated with authentic Hipparcos (HIP) and Yale Bright Star Catalogue (BSC5) data (219 prominent stars) including spectral classifications, apparent magnitudes, parallax, proper motion, and B-V color indices.
- **Dynamic Planetary Visuals**: Distinct visual rendering for the Sun (radiant corona and photosphere), Moon (phase crescent and illumination), Saturn (tilted ring ellipse), Jupiter, Mars, and other planets with astronomical symbols and labels.
- **Camera Spherical Perspective Projection**: Perspective sky projection using 3D camera matrices with field-of-view zooming (25° to 110°), seamless 360° azimuth wrapping, zenith crossing support, and back-plane clipping.
- **Device Orientation & AR Tracking**: Fuses calibrated compass heading (`flutter_compass`) and accelerometer gravity vector (`sensors_plus`) with vector-based circular angle smoothing and manual calibration offsets.
- **Location & Time Control**: Auto-detects GPS observer coordinates via `geolocator`, supports manual latitude/longitude entry, global observatory presets, and simulated/live observation time.
- **Night-Vision Mode**: High-contrast red-and-black monochrome theme to preserve dark-adapted vision during telescope observation.
- **Unified Celestial Search & Astrometry**: Real-time multi-category search across Solar System planets, all 88 constellations, and catalogue stars with instant map centering and comprehensive astrophysical details.

---

## 2. Project Architecture

The codebase adheres to clean, decoupled architecture:

```
lib/
  main.dart                               # Application bootstrap, orientation & preferences setup
  app/
    app.dart                              # Root AstroTrackApp widget
    theme.dart                            # Dark & Red Night-Vision theme definitions
  models/
    celestial_object.dart                 # Base class for equatorial bodies
    sky_position.dart                     # Horizontal topocentric coordinates (Az, Alt, Hour Angle)
    star.dart                             # Star astrometry, spectral colors, JSON serialization
    constellation.dart                    # Constellation asterisms and catalogue star-pair lines
    observer_location.dart                # Observer latitude, longitude, elevation, presets
    observation_time.dart                 # UTC time management, simulation speeds, clock sync
  astronomy/
    spherical_geometry.dart               # Angle normalization, 3D unit vectors, Vincenty distance
    astronomical_time.dart                # Julian Date (JD) and Julian centuries (T) algorithms
    sidereal_time.dart                    # IAU Greenwich Mean Sidereal Time (GMST) and LST
    coordinate_transform.dart             # Equatorial <-> Horizontal transforms, Precession, Bennett Refraction
    star_position_calculator.dart         # High-performance batch matrix coordinate calculator
    astronomy_engine.dart                 # State coordinator for time, location, and sky positions
  sensors/
    heading_calibration.dart              # Manual heading offsets and sensor accuracy ratings
    device_orientation_service.dart       # Compass + accelerometer sensor fusion & vector smoothing
  services/
    location_service.dart                 # GPS positioning with non-fatal permission guards
    preferences_service.dart              # SharedPreferences persistence of settings
  rendering/
    sky_projection.dart                   # Perspective 3D spherical camera projection
    star_rendering_style.dart             # Visual themes, Pogson magnitude scaling, limits
    star_map_painter.dart                 # CustomPainter for stars, glows, grids, constellations
  screens/
    sky_map_screen.dart                   # Main interactive canvas with gesture control & HUD
    search_screen.dart                    # Celestial object search and real-time visibility filters
    star_details_screen.dart              # Detailed astrophysical property breakdown
    settings_screen.dart                  # GPS detection, manual coordinates, calibration sliders
    time_selection_screen.dart            # Date & time picker, fast stepping, JD ephemeris metrics
  widgets/
    star_information_card.dart            # Bottom sheet displaying selected star properties
    sky_map_controls.dart                 # Floating cluster: AR tracking, zoom, grid, night mode
    location_indicator.dart               # Top HUD observer coordinate chip
    orientation_indicator.dart            # Top HUD azimuth, altitude, and sensor status
    brightness_control.dart               # Limiting magnitude slider control

assets/
  catalogues/
    stars.json                            # Bundled real Hipparcos / BSC5 star catalogue
  constellations/
    constellations.json                   # Verified constellation line connections

test/
  astronomy/
    astronomy_test.dart                   # 18 unit tests for JD, GMST, LST, transforms, edge cases
  rendering/
    projection_test.dart                  # Perspective projection, clipping, and zoom scaling tests
  widgets/
    star_card_test.dart                   # Widget test for StarInformationCard
    sky_map_screen_test.dart              # Widget test for SkyMapScreen and HUD controls
```

---

## 3. Mathematical Model & Astronomical Conventions

### 3.1 Time & Epochs
- **Time Scale**: UTC is strictly utilized for internal ephemeris calculations.
- **Julian Date ($JD$)**: Computed using Meeus (Chapter 7) Gregorian algorithm:
  $$T = \frac{JD - 2451545.0}{36525.0} \quad \text{(Julian centuries from J2000.0)}$$
- **Greenwich Mean Sidereal Time ($GMST$)**:
  $$GMST = 280.46061837^\circ + 360.98564736629^\circ \cdot (JD - 2451545.0) + 0.000387933^\circ \cdot T^2 - \frac{T^3}{38710000}^\circ \pmod{360^\circ}$$
- **Observer Longitude ($\lambda$)**: East-positive convention ($+77.2^\circ$ for East, $-74.0^\circ$ for West).
- **Local Sidereal Time ($LST$)**:
  $$LST = (GMST + \lambda) \pmod{360^\circ}$$

### 3.2 Equatorial to Horizontal Transformation
Given target Right Ascension $\alpha$, Declination $\delta$, and observer Latitude $\phi$:
- **Hour Angle ($H$)**:
  $$H = (LST - \alpha) \pmod{360^\circ}$$
- **Altitude ($a$)**:
  $$\sin a = \sin \phi \sin \delta + \cos \phi \cos \delta \cos H$$
  $$a = \arcsin(\text{clamp}(\sin a, -1.0, 1.0))$$
- **Azimuth ($A$)** (measured clockwise from True North: $0^\circ = \text{North}, 90^\circ = \text{East}, 180^\circ = \text{South}, 270^\circ = \text{West}$):
  $$A = \text{atan2}(-\sin H \cos \delta, \; \sin \delta \cos \phi - \cos \delta \sin \phi \cos H) \pmod{360^\circ}$$
- **Zenith Singularity Handling**: At $a \ge 89.9999^\circ$, azimuth is geometrically degenerate. The engine explicitly sets $A = 0.0^\circ$ to prevent `NaN` or division-by-zero errors.

### 3.3 Astrometric Corrections
- **Precession**: IAU 1976 / Lieske et al. 3D rotation matrix calculation ($R_z(-z_A) \cdot R_y(\theta_A) \cdot R_z(-\zeta_A)$) from J2000.0 to epoch of date.
- **Proper Motion**: Annual proper motion in RA ($\mu_\alpha \cos\delta$) and Dec ($\mu_\delta$) applied relative to J2000.0.
- **Atmospheric Refraction**: Bennett (1982) formula for apparent altitude elevation:
  $$R = \frac{1}{\tan\left(a + \frac{7.31}{a + 4.4}\right)} \text{ arcminutes} \quad (a \ge -1.0^\circ)$$

---

## 4. Dependencies

| Package | Version | Justification |
| :--- | :--- | :--- |
| `flutter` | SDK | Cross-platform UI toolkit and canvas rendering |
| `sensors_plus` | ^7.1.1 | Fused accelerometer sensor stream for pitch and roll |
| `flutter_compass` | ^0.8.1 | Hardware magnetometer heading and accuracy reporting |
| `geolocator` | ^14.1.2 | GPS coordinate detection with non-fatal permission guards |
| `shared_preferences`| ^2.5.5 | Local persistence of location, calibration, and visual preferences |
| `vector_math` | ^2.2.0 | 3D Cartesian topocentric vector operations and transformations |

---

## 5. Android Permissions & Setup

Configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-feature android:name="android.hardware.sensor.compass" android:required="false" />
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="false" />
<uses-feature android:name="android.hardware.location.gps" android:required="false" />
```

*Note: Background location access is strictly omitted. Hardware features are marked non-required so the app operates smoothly with manual panning on devices without magnetometers.*

---

## 6. Execution & Build Instructions

### Running Unit & Widget Tests
```bash
flutter test
```
*Executes all 35 astronomical unit tests, planetary ephemeris validations, and UI widget tests.*

### Running Static Analysis & Formatting
```bash
dart format lib test
flutter analyze
```

### Running Locally
```bash
flutter run
```

### Building the Android APK
```bash
flutter build apk --debug
```
The output APK is generated at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 7. Running on a Physical Android Phone

1. Enable **Developer Options** and **USB Debugging** on your Android smartphone.
2. Connect your device via USB cable. Verify detection with:
   ```bash
   flutter devices
   ```
3. Install and run directly:
   ```bash
   flutter run -d <device-id>
   ```
4. **Compass Calibration**: When in device tracking mode (AR mode), if heading appears offset due to local magnetic interference, wave the phone in a slow figure-8 motion or adjust the manual heading slider in **Settings**.
#   s t a r - t r a c k e r  
 