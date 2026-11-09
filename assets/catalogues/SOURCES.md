# Catalogue sources and coordinate conventions

- `stars.json` is the app's curated Hipparcos / Yale Bright Star Catalogue subset. Coordinates are tagged as J2000.0; individual additions name SIMBAD or Hipparcos provenance in the `source` field.
- `deep_sky.json` uses OpenNGC for NGC/IC identifications, positions, sizes, and magnitudes where present. OpenNGC is distributed under CC BY-SA 4.0. Named objects and extended features, including the approximate Cygnus Rift boundary, retain their SIMBAD provenance in each record. Coordinates use J2000.0.
- The IAU constellation list contains 88 records and keeps its line connections tied to HIP identifiers in the star catalogue.
- Additional asteroid and dwarf-planet positions use JPL Small-Body Database osculating elements at the epoch stored in `planetary_ephemeris.dart`. The offline Kepler propagation omits perturbations; it is intended for sky-map finding, not precision ephemerides.
- Galilean satellite positions use JPL Horizons osculating elements for 2026-01-01 and two-body propagation. Their displayed positions are approximate.
- Meteor-shower activity dates follow the International Meteor Organization calendar. Radiant coordinates are representative J2000 positions; real radiants drift during the shower.

Sources: [OpenNGC](https://github.com/mattiaverga/OpenNGC), [SIMBAD](https://simbad.cds.unistra.fr/), [JPL SBDB API](https://ssd-api.jpl.nasa.gov/doc/sbdb.html), [JPL Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html), [IAU constellations](https://www.iau.org/IAU/Astronomy-FAQs/Constellations.aspx), [IMO meteor calendar](https://www.imo.net/calendar/).
