#!/usr/bin/env python3
"""Downloads the propagation (visibility) tiles of all sites from HamnetDB.

Based on endpoint provided by Lucas Speckbacher, oe2lsp in 2022

For each site on the map (https://repeater.oevsv.at/api/site_type):
  1. its name and position,
  2. the directory name as the website uses it for the overlay
     (frqmap.component.ts: " " -> "-", "/" -> "_"; e.g. tiles/Mittersill-Ort/9/276/179.png),
  3. https://hamnetdb.net/rftools/calc_visibility.cgi for that position, which
     calculates the visibility and answers with export.zip (tiles z/x/y.png),
  4. waits for the download (about 1-2 minutes),
  5. pauses as long as the download took (not to overload HamnetDB),
  6. stores the zip as <name>.zip,
  7. extracts it to <name>/,
then goes on with the next site.

    python3 propagation_tiles.py                         # all sites -> /var/www/tiles-<date>
    python3 propagation_tiles.py /path                   # all sites -> /path
    python3 propagation_tiles.py /path --site Nebelstein --site "Mittersill Ort"   # only these

Sites whose directory already exists are skipped, so an interrupted run can
simply be started again. Errors of one site are reported, then the next site
follows; the exit status is 1 if any site failed.
"""

import argparse
import os
import shutil
import sys
import time
import zipfile
from datetime import date

import requests

SITES_URL = "https://repeater.oevsv.at/api/site_type?select=site_name,latitude,longitude&order=site_name"
VISIBILITY_URL = "https://hamnetdb.net/rftools/calc_visibility.cgi"
TIMEOUT = 600  # seconds for one calculation + download


def dir_name(site_name):
    """As the website builds the overlay URL: spaces -> "-", slashes -> "_"."""
    return site_name.replace(" ", "-").replace("/", "_")


def visibility_params(lat, lon, antenna):
    # Site A = the repeater; site B is unused (0/0) when only the visibility is exported (e=1).
    return {"lon_a": lon, "lat_a": lat, "ant_a": antenna, "lon_b": 0, "lat_b": 0,
            "ant_b": 10, "ant_c": 2, "ref": 0.25, "e": 1}


def download(name, lat, lon, out_dir, antenna):
    """Steps 3-7 for one position, stored as <name>.zip and <name>/. Returns
    the seconds the download took."""
    zip_path = os.path.join(out_dir, name + ".zip")
    part_path = zip_path + ".part"
    target = os.path.join(out_dir, name)

    start = time.monotonic()
    with requests.get(VISIBILITY_URL, params=visibility_params(lat, lon, antenna),
                      stream=True, timeout=TIMEOUT) as response:
        response.raise_for_status()
        with open(part_path, "wb") as f:
            for chunk in response.iter_content(1 << 16):
                f.write(chunk)
    took = time.monotonic() - start

    if not zipfile.is_zipfile(part_path):
        with open(part_path, "rb") as f:
            head = f.read(200)
        os.remove(part_path)
        raise RuntimeError(f"no zip file received: {head!r}")
    os.replace(part_path, zip_path)

    # Extract to <name>.tmp first, so <name>/ only exists when complete
    # (zipfile drops absolute paths and "..").
    tmp = target + ".tmp"
    shutil.rmtree(tmp, ignore_errors=True)
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(tmp)
        files = sum(1 for i in z.infolist() if not i.is_dir())
    os.replace(tmp, target)
    print(f"  {os.path.getsize(zip_path) / 1e6:.1f} MB, {files} files, {took:.0f} s -> {target}", flush=True)
    return took


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("path", nargs="?", default=f"/var/www/tiles-{date.today().isoformat()}",
                        help="output directory (default: /var/www/tiles-<date>)")
    parser.add_argument("--site", action="append",
                        help="only this site (name as on the map); can be given several times")
    parser.add_argument("--antenna", type=float, default=15,
                        help="antenna height of the site above ground in m (default: 15)")
    args = parser.parse_args()

    sites = requests.get(SITES_URL, timeout=60).json()
    if args.site:
        wanted = set(args.site)
        sites = [s for s in sites if s["site_name"] in wanted]
        missing = wanted - {s["site_name"] for s in sites}
        if missing:
            print(f"Unknown site(s): {', '.join(sorted(missing))}", file=sys.stderr)
            return 1
    return download_all([(s["site_name"], dir_name(s["site_name"]), s["latitude"], s["longitude"]) for s in sites],
                        args.path, args.antenna)


def download_all(entries, out_dir, antenna):
    """Downloads one entry (label, name, lat, lon) after the other, with a pause
    as long as each download took; existing <name>/ directories are skipped.
    Returns the exit status: 1 if any entry failed. Also used by sota_tiles.py."""
    os.makedirs(out_dir, exist_ok=True)
    failed = []
    for i, (label, name, lat, lon) in enumerate(entries, 1):
        print(f"[{i}/{len(entries)}] {label} ({lat}, {lon})", flush=True)
        if os.path.isdir(os.path.join(out_dir, name)):
            print("  exists, skipped", flush=True)
            continue
        if lat is None or lon is None:
            print("  no position, skipped", flush=True)
            failed.append(label)
            continue
        start = time.monotonic()
        try:
            took = download(name, lat, lon, out_dir, antenna)
        except Exception as e:  # report, go on with the next one
            took = time.monotonic() - start
            print(f"  FAILED: {e}", flush=True)
            failed.append(label)
        if i < len(entries):
            print(f"  pause {took:.0f} s", flush=True)
            time.sleep(took)

    if failed:
        print(f"Failed: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
