"""Refresh the bundled HIP subset with Gaia DR3 astrometry.

The app ships this catalogue so star positions remain available offline. Run
this tool when refreshing the catalogue; unmatched or incomplete Gaia records
retain their existing Hipparcos/Yale values.
"""

from __future__ import annotations

import csv
import io
import json
from pathlib import Path
import re
from urllib.parse import quote
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
STARS_PATH = ROOT / "assets" / "catalogues" / "stars.json"
FALLBACK_PATH = ROOT / "lib" / "data" / "default_stars_data.dart"
TAP_URL = "https://gea.esac.esa.int/tap-server/tap/sync"
FALLBACK_PREFIX = "// GENERATED CURATED STAR CATALOGUE DATA\nconst String allCatalogueStarsJson = r'''\n"
FALLBACK_SUFFIX = "\n''';\n"


def fetch_gaia_rows(hip_numbers: list[int]) -> list[dict[str, str]]:
    ids = ",".join(str(value) for value in sorted(set(hip_numbers)))
    query = (
        "SELECT h.original_ext_source_id, g.source_id, g.ra, g.dec, "
        "g.parallax, g.pmra, g.pmdec, g.ref_epoch "
        "FROM gaiadr3.hipparcos2_best_neighbour h "
        "JOIN gaiadr3.gaia_source g ON g.source_id=h.source_id "
        f"WHERE h.original_ext_source_id IN ({ids})"
    )
    request_url = f"{TAP_URL}?REQUEST=doQuery&LANG=ADQL&FORMAT=csv&QUERY={quote(query)}"
    request = Request(request_url, headers={"User-Agent": "AstroTrack catalogue updater/1.0"})
    with urlopen(request, timeout=60) as response:
        return list(csv.DictReader(io.StringIO(response.read().decode("utf-8"))))


def write_catalogue(stars: list[dict[str, object]]) -> None:
    encoded = json.dumps(stars, indent=2, ensure_ascii=False) + "\n"
    STARS_PATH.write_text(encoded, encoding="utf-8")
    FALLBACK_PATH.write_text(
        FALLBACK_PREFIX + encoded.rstrip() + FALLBACK_SUFFIX,
        encoding="utf-8",
    )


def main() -> None:
    stars: list[dict[str, object]] = json.loads(STARS_PATH.read_text(encoding="utf-8"))
    by_hip = {}
    for star in stars:
        match = re.fullmatch(r"HIP (\d+)", str(star.get("id", "")))
        if match:
            by_hip[int(match.group(1))] = star
    rows = fetch_gaia_rows(list(by_hip))

    updated = 0
    incomplete = 0
    for row in rows:
        hip = int(row["original_ext_source_id"])
        star = by_hip.get(hip)
        if star is None:
            continue

        # Gaia DR3 positions are at ref_epoch. Only change the record as a
        # whole when its proper-motion pair is available too.
        required = ("ra", "dec", "pmra", "pmdec", "ref_epoch")
        if any(not row.get(column) for column in required):
            incomplete += 1
            continue

        star["ra"] = float(row["ra"])
        star["dec"] = float(row["dec"])
        star["pmRa"] = float(row["pmra"])
        star["pmDec"] = float(row["pmdec"])
        star["epoch"] = float(row["ref_epoch"])
        if row.get("parallax"):
            parallax = float(row["parallax"])
            star["plx"] = parallax
            if parallax > 0:
                star["dist"] = 3261.563777 / parallax

        prior_source = str(star.get("source") or "Hipparcos/Yale catalogue")
        simbad_suffix = "; SIMBAD identifiers via CDS Sesame"
        has_simbad_source = simbad_suffix in prior_source
        if prior_source.startswith("Gaia DR3 source_id "):
            marker = "; names and photometry retained from "
            if marker in prior_source:
                prior_source = prior_source.split(marker, 1)[1]
            prior_source = prior_source.replace(simbad_suffix, "")
        star["source"] = (
            f"Gaia DR3 source_id {row['source_id']} astrometry; "
            f"names and photometry retained from {prior_source}"
        )
        if has_simbad_source:
            star["source"] += simbad_suffix
        updated += 1

    write_catalogue(stars)
    print(
        f"Updated {updated} stars from Gaia DR3; "
        f"left {incomplete} incomplete Gaia matches and "
        f"{len(by_hip) - len(rows)} unmatched HIP records unchanged."
    )


if __name__ == "__main__":
    main()
