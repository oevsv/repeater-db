#!/usr/bin/python3
"""Runs the scrapers: all of them, or those named on the command line.

    python3 scrap_all.py                      # all
    python3 scrap_all.py scrap_dmr_ipsc2 ...  # only these (names = table names)

Each scraper appends a snapshot to its scrap_* table. A failing scraper (site
down, page layout changed, database error) is reported and the others still
run. Exit status: 0 if all succeeded, 1 otherwise (the systemd unit then fails), 2 for
an unknown scraper name.
"""

import sys
import traceback

from scrapers import SCRAPERS


def scrap_all(names=None):
    """Runs the given scrapers (default: all); returns 0 if all succeeded, else 1."""
    names = names or list(SCRAPERS)
    failed = []
    for name in names:
        try:
            SCRAPERS[name]()
        except Exception as e:
            failed.append(name)
            print(f"FAILED {name}: {e}", file=sys.stderr, flush=True)
            traceback.print_exc(file=sys.stderr)
    print(f"{len(names) - len(failed)} of {len(names)} scrapers succeeded"
          + (f", failed: {', '.join(failed)}" if failed else "."), flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    unknown = [n for n in sys.argv[1:] if n not in SCRAPERS]
    if unknown:
        print(f"Unknown scraper(s): {', '.join(unknown)}. Available: {', '.join(SCRAPERS)}",
              file=sys.stderr)
        sys.exit(2)
    sys.exit(scrap_all(sys.argv[1:]))
