#!/usr/bin/env python3
"""Downloads the propagation (visibility) tiles of all Austrian SOTA summits
from HamnetDB, like propagation_tiles.py does for the sites (same download,
pause, zip and extraction; see there).

The summits are the map's copy of the SOTA list (association OE, about 2,200
summits): https://repeater.oevsv.at/de/assets/sota-OE.json (GeoJSON, in the
website repo src/assets/sota-OE.json). Each summit is stored under its
reference with "/" -> "_": OE/ST-174 -> OE_ST-174.zip and OE_ST-174/.
The website does not show these tiles (yet).

    python3 sota_tiles.py                                # all summits -> /var/www/tiles-sota-<date>
    python3 sota_tiles.py /path                          # all summits -> /path
    python3 sota_tiles.py /path --summit OE/ST-174 --summit OE/KT-001   # only these

One summit takes about 1-2 minutes plus the same pause: all of them run for
days. Summits whose directory already exists are skipped, so the script can be
stopped and started again at any time.
"""

import argparse
import sys
from datetime import date

import requests

from propagation_tiles import download_all

SUMMITS_URL = "https://repeater.oevsv.at/de/assets/sota-OE.json"


def dir_name(reference):
    """OE/ST-174 -> OE_ST-174."""
    return reference.replace("/", "_").replace(" ", "-")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("path", nargs="?", default=f"/var/www/tiles-sota-{date.today().isoformat()}",
                        help="output directory (default: /var/www/tiles-sota-<date>)")
    parser.add_argument("--summit", action="append",
                        help="only this summit (reference, e.g. OE/ST-174); can be given several times")
    parser.add_argument("--antenna", type=float, default=2,
                        help="antenna height above ground in m (default: 2, portable)")
    parser.add_argument("--summits-url", default=SUMMITS_URL, help=f"GeoJSON of the summits (default: {SUMMITS_URL})")
    args = parser.parse_args()

    features = requests.get(args.summits_url, timeout=60).json()["features"]
    summits = sorted((f["properties"]["code"], *f["geometry"]["coordinates"][:2]) for f in features)
    if args.summit:
        wanted = {s.upper() for s in args.summit}
        summits = [s for s in summits if s[0] in wanted]
        missing = wanted - {s[0] for s in summits}
        if missing:
            print(f"Unknown summit(s): {', '.join(sorted(missing))}", file=sys.stderr)
            return 1

    return download_all([(code, dir_name(code), lat, lon) for code, lon, lat in summits], args.path, args.antenna)


if __name__ == "__main__":
    sys.exit(main())
