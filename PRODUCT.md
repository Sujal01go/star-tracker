# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Casual skywatchers and telescope users who want to know what they can observe
from their current location and prepare a practical observing session.

## Product Purpose

AstroTrack helps people explore the current sky, identify celestial targets,
follow their positions, and prepare telescope observations.

## Positioning

AstroTrack connects sky catalogues and calculated local positions to an
orientation-aware sky map, target search, and telescope setup instruments in
one observing workflow.

## Operating Context

People use the app outdoors while identifying targets or preparing a telescope.
Location and observation time affect which targets are useful, and a session may
be planned before switching to the live sky map.

## Capabilities and Constraints

- The Flutter app targets Android, iOS, desktop, and web; Android is the
  confirmed primary platform for product decisions.
- The app calculates local horizontal positions for Solar System objects,
  stars, and constellations from observer location and observation time.
- The sky map supports device orientation tracking and manual viewing.
- The app includes target search, telescope setup instruments, and an observing
  catalogue with bundled offline data.
- Recommendations should be derived from available astronomical data. Do not
  claim weather, cloud cover, or other external observing conditions unless a
  real data source is connected.

## Brand Commitments

AstroTrack is a calm, space-themed observing tool. Keep its interface clean and
user friendly, use the established violet, rose, and saffron palette, and avoid
unnecessary gradients and glowing buttons.

## Evidence on Hand

- Planetary positions: `lib/astronomy/astronomy_engine.dart` and
  `lib/astronomy/planetary_ephemeris.dart`.
- Star catalogue: `lib/data/star_catalogue_repository.dart` and
  `lib/data/default_stars_data.dart`.
- Sky map and device tracking: `lib/screens/sky_map_screen.dart` and
  `lib/sensors/device_orientation_service.dart`.
- Telescope setup instruments: `lib/screens/telescope_setup_screen.dart`.

## Product Principles

- Make current, local sky conditions useful at a glance.
- Let every observing recommendation lead directly to the target on the sky map.
- Be clear about what the available data can and cannot establish.
- Keep essential catalogues and observing tools available offline where bundled
  data supports them.
