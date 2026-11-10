"""Build the offline J2000 IAU constellation-boundary asset.

Input edges are the B1875 Delporte boundaries, sampled before precession so
the curved J2000 paths are represented smoothly on the sky map.
"""

from __future__ import annotations

import json
import math
import re
from pathlib import Path
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "assets" / "constellations" / "iau_boundaries.json"
SOURCE_URL = "https://pbarbier.com/constellations/edges_18.txt"
LINE = re.compile(
    r"^\d+:\d+\s+([MP][+-])\s+"
    r"(\d{2}:\d{2}:\d{2})\s+([+-]\d{2}:\d{2}:\d{2})\s+"
    r"(\d{2}:\d{2}:\d{2})\s+([+-]\d{2}:\d{2}:\d{2})\s+"
    r"([A-Z]{3})\s+([A-Z]{3})"
)


def sexagesimal(value: str, hours: bool = False) -> float:
    sign = -1 if value.startswith("-") else 1
    fields = value.lstrip("+-").split(":")
    result = float(fields[0]) + float(fields[1]) / 60 + float(fields[2]) / 3600
    return sign * result * (15 if hours else 1)


def precess(ra_deg: float, dec_deg: float, from_epoch: float, to_epoch: float) -> tuple[float, float]:
    """Meeus/IAU 1976 precession from one equinox to another."""
    t0 = (from_epoch - 2000.0) / 100.0
    t = (to_epoch - from_epoch) / 100.0
    t0_sq = t0 * t0
    zeta = (
        (2306.2181 + 1.39656 * t0 - 0.000139 * t0_sq) * t
        + (0.30188 - 0.000344 * t0) * t * t
        + 0.017998 * t * t * t
    ) / 3600
    z = (
        (2306.2181 + 1.39656 * t0 - 0.000139 * t0_sq) * t
        + (1.09468 + 0.000066 * t0) * t * t
        + 0.018203 * t * t * t
    ) / 3600
    theta = (
        (2004.3109 - 0.85330 * t0 - 0.000217 * t0_sq) * t
        - (0.42665 + 0.000217 * t0) * t * t
        - 0.041833 * t * t * t
    ) / 3600

    alpha = math.radians(ra_deg)
    delta = math.radians(dec_deg)
    zeta_rad, z_rad, theta_rad = map(math.radians, (zeta, z, theta))
    a = math.cos(delta) * math.sin(alpha + zeta_rad)
    b = (
        math.cos(theta_rad) * math.cos(delta) * math.cos(alpha + zeta_rad)
        - math.sin(theta_rad) * math.sin(delta)
    )
    c = (
        math.sin(theta_rad) * math.cos(delta) * math.cos(alpha + zeta_rad)
        + math.cos(theta_rad) * math.sin(delta)
    )
    return math.degrees(math.atan2(a, b) + z_rad) % 360, math.degrees(math.asin(c))


def interpolate_edge(
    kind: str,
    start_ra: float,
    start_dec: float,
    end_ra: float,
    end_dec: float,
) -> list[list[float]]:
    delta_ra = ((end_ra - start_ra + 180) % 360) - 180
    # The source's M/P marker describes the exact B1875 axis-aligned edge.
    if kind.startswith("M"):
        delta_ra = 0.0
    else:
        end_dec = start_dec
    mean_dec = math.radians((start_dec + end_dec) / 2)
    delta_dec = end_dec - start_dec
    angular_length = math.hypot(delta_dec, delta_ra * math.cos(mean_dec))
    steps = max(1, math.ceil(angular_length / 0.75))
    points: list[list[float]] = []
    for index in range(steps + 1):
        fraction = index / steps
        ra = (start_ra + delta_ra * fraction) % 360
        dec = start_dec + delta_dec * fraction
        ra_j2000, dec_j2000 = precess(ra, dec, 1875.0, 2000.0)
        points.append([round(ra_j2000, 6), round(dec_j2000, 6)])
    return points


def main() -> None:
    request = Request(SOURCE_URL, headers={"User-Agent": "AstroTrack boundary asset builder/1.0"})
    with urlopen(request, timeout=45) as response:
        source = response.read().decode("ascii")

    boundaries = []
    for raw_line in source.splitlines():
        match = LINE.match(raw_line.strip())
        if match is None:
            continue
        kind, ra1, dec1, ra2, dec2, first, second = match.groups()
        boundaries.append(
            {
                "constellations": [first, second],
                "points": interpolate_edge(
                    kind,
                    sexagesimal(ra1, hours=True),
                    sexagesimal(dec1),
                    sexagesimal(ra2, hours=True),
                    sexagesimal(dec2),
                ),
            }
        )

    if len(boundaries) < 700:
        raise RuntimeError(f"Unexpected boundary source: parsed only {len(boundaries)} edges")
    OUTPUT_PATH.write_text(json.dumps(boundaries, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"Wrote {len(boundaries)} IAU shared boundary edges to {OUTPUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
