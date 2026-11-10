"""Add useful SIMBAD identifiers to the bundled bright-star catalogue.

The application is offline-first, so this tool snapshots identifiers for the
bright curated stars into its JSON asset and compiled fallback.
"""

from __future__ import annotations

import json
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
STARS_PATH = ROOT / "assets" / "catalogues" / "stars.json"
FALLBACK_PATH = ROOT / "lib" / "data" / "default_stars_data.dart"
ENDPOINT = "https://vizier.cfa.harvard.edu/viz-bin/nph-sesame/-oxpI/SNVA"
FALLBACK_PREFIX = "// GENERATED CURATED STAR CATALOGUE DATA\nconst String allCatalogueStarsJson = r'''\n"
FALLBACK_SUFFIX = "\n''';\n"
USEFUL_PREFIXES = ("HIP ", "HD ", "HR ", "SAO ", "GJ ", "HIC ", "NAME ")


def add_aliases_from_simbad(stars: list[dict[str, object]]) -> int:
    targets: dict[str, list[dict[str, object]]] = {}
    for star in stars:
        magnitude = float(star.get("mag", 99))
        name = str(star.get("commonName") or "").strip()
        if name and magnitude <= 2.5:
            targets.setdefault(name.casefold(), []).append(star)
    if not targets:
        return 0

    encoded_names = "&".join(quote(name, safe="") for name in targets)
    request = Request(
        f"{ENDPOINT}?{encoded_names}",
        headers={"User-Agent": "AstroTrack catalogue updater/1.0"},
    )
    with urlopen(request, timeout=120) as response:
        root = ElementTree.fromstring(response.read())

    updated = 0
    for target in root.findall("Target"):
        name = (target.findtext("name") or "").strip().casefold()
        matching_stars = targets.get(name, [])
        if not matching_stars:
            continue
        resolver = next(
            (
                item
                for item in target.findall("Resolver")
                if "Simbad" in (item.attrib.get("name") or "")
            ),
            None,
        )
        if resolver is None:
            continue

        aliases = []
        for element in resolver.findall("alias"):
            alias = " ".join((element.text or "").split())
            if alias.startswith("NAME "):
                alias = alias[5:]
            if alias and alias.upper().startswith(USEFUL_PREFIXES):
                aliases.append(alias)
        main_identifier = " ".join((resolver.findtext("oname") or "").split())
        if main_identifier:
            aliases.append(main_identifier)

        for star in matching_stars:
            existing = star.get("aliases")
            combined = list(existing) if isinstance(existing, list) else []
            seen = {str(value).casefold() for value in combined}
            for alias in aliases:
                if alias.casefold() not in seen:
                    combined.append(alias)
                    seen.add(alias.casefold())
            if combined:
                star["aliases"] = combined
            source = str(star.get("source") or "curated star catalogue")
            if "SIMBAD identifiers" not in source:
                star["source"] = f"{source}; SIMBAD identifiers via CDS Sesame"
            updated += 1
    return updated


def main() -> None:
    stars: list[dict[str, object]] = json.loads(STARS_PATH.read_text(encoding="utf-8"))
    updated = add_aliases_from_simbad(stars)
    encoded = json.dumps(stars, indent=2, ensure_ascii=False) + "\n"
    STARS_PATH.write_text(encoded, encoding="utf-8")
    FALLBACK_PATH.write_text(
        FALLBACK_PREFIX + encoded.rstrip() + FALLBACK_SUFFIX,
        encoding="utf-8",
    )
    print(f"Added SIMBAD aliases and identifiers for {updated} bright catalogue stars.")


if __name__ == "__main__":
    main()
