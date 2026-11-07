"""Shared code of the scrap_*.py scrapers.

Each scraper downloads one web page, picks the stations of interest and appends
them as a snapshot (all rows with the same scraped_timestamp) to its scrap_*
table. A scraper only describes where its rows are and how one row maps to
table columns; downloading, the snapshot timestamp and storing are done here.

Scrapers return the number of rows inserted and raise an exception on any
failure (download, unexpected page layout, database), so that scrap_all.py can
report it and exit with a non-zero status.

Callsigns are always stored in a column "callsign", in upper case. Where a page
only shows a callsign with a suffix (e.g. a D-STAR module "OE9XGV-B"), the
original value is stored as well and "callsign" holds it without the suffix
("OE9XGV"), see base_callsign().
"""

import getpass
import os
import re
from datetime import datetime, timezone

import psycopg
import requests
from bs4 import BeautifulSoup
from psycopg import sql

from load_db_config import load_db_config

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Database config: as systemd credential (LoadCredential=db_config.ini:..., see
# systemd/repeater-scrap.service), else db_config.ini next to the scripts
# (gitignored), wherever they are started from.
DB_CONFIG_FILE = os.path.join(os.environ.get('CREDENTIALS_DIRECTORY') or SCRIPT_DIR, 'db_config.ini')

# Some of the pages only answer browser-like user agents.
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/105.0.0.0 Safari/537.36"
}
TIMEOUT = 15  # seconds per request, so a hanging site can't block the whole run


class ScrapError(Exception):
    """The page could be downloaded but did not contain what we expected."""


# --- downloading / parsing --------------------------------------------------

def fetch(url, method="get", session=None, **kwargs):
    """Downloads a page and returns the response (raises on HTTP errors)."""
    client = session or requests
    response = client.request(method, url, headers=HEADERS, timeout=TIMEOUT, **kwargs)
    response.raise_for_status()
    return response


def get_soup(url, **kwargs):
    """Downloads and parses a page (arguments as for fetch())."""
    return BeautifulSoup(fetch(url, **kwargs).text, "html.parser")


def find_all(soup, url, *args, **kwargs):
    """soup.find_all(*args, **kwargs), raising ScrapError if nothing is found
    (the page layout probably changed)."""
    found = soup.find_all(*args, **kwargs)
    if not found:
        raise ScrapError(f"{url}: nothing found for {args} {kwargs}")
    return found


def row_cells(row, count):
    """The stripped texts of the first `count` <td> cells of a table row, or
    None for rows with fewer cells or without any content (headers, spacers)."""
    cells = [td.get_text(strip=True) for td in row.find_all("td")]
    if len(cells) < count or not any(cells):
        return None
    return cells[:count]


# --- callsigns --------------------------------------------------------------

def callsign(text):
    """A callsign as stored: stripped, upper case ("oe7xbi" -> "OE7XBI")."""
    return (text or "").strip().upper()


def base_callsign(text):
    """The callsign without a suffix, upper case: "OE9XGV-B" -> "OE9XGV",
    "HB9DR-2" -> "HB9DR", "FCS22820  -335555" -> "FCS22820". Everything from
    the first "-" or blank on is the suffix."""
    match = re.match(r"[^-\s]+", (text or "").strip())
    return match.group(0).upper() if match else ""


# --- storing ------------------------------------------------------------------

def utc_now():
    """Current time in UTC, without time zone (the scrap_* tables use TIMESTAMP)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def save(table, items, to_record, replace=False):
    """Turns each item (e.g. a table row) into a record with to_record(item) -
    a dict {column: value}, or None to skip the item - and inserts them all,
    with one scraped_timestamp, into table. Returns the number of rows.
    replace: the table keeps no history - its rows are deleted first, in the
    same transaction (on any failure the previous rows stay)."""
    now = utc_now()
    records = [r for r in map(to_record, items) if r is not None]
    if not records:
        raise ScrapError(f"{table}: nothing to insert - did the page layout change?")
    columns = [*records[0], "scraped_timestamp"]
    query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
        sql.Identifier(table),
        sql.SQL(", ").join(map(sql.Identifier, columns)),
        sql.SQL(", ").join(sql.Placeholder() * len(columns)),
    )
    db_config = load_db_config(filename=DB_CONFIG_FILE, section='postgresql')
    try:
        conn = psycopg.connect(**db_config)
    except psycopg.OperationalError as e:
        # Name what was tried: with a password login the role and config
        # matter; with peer authentication (local socket) also the system user,
        # which must have the role's name.
        raise ScrapError(f"{e} (system user {getpass.getuser()!r}, database role "
                         f"{db_config.get('user')!r}, config {DB_CONFIG_FILE})") from e
    # The connection commits on success, rolls back on an exception, then closes.
    with conn:
        cursor = conn.cursor()
        if replace:
            cursor.execute(sql.SQL("DELETE FROM {}").format(sql.Identifier(table)))
        cursor.executemany(query, [(*r.values(), now) for r in records])
    print(f"Inserted {len(records)} rows into {table}.", flush=True)
    return len(records)


# --- the "_status.html" pages of the OEVSV servers ---------------------------

def scrap_status_page(url, table, to_record):
    """Scrapes the data rows (class="trow") of an OEVSV "_status.html" page."""
    soup = get_soup(url)
    return save(table, find_all(soup, url, "tr", class_="trow"), to_record)


# The DMR servers (IPSC2, hotspots, OE-Link) share one layout of 12 cells:
#   NR, REPEATER, INFO, ID, TS1, CQ, TS1-INFO, TS2, TS2-INFO, REF, START, HARDWARE
DMR_COLUMNS = ["nr", "callsign", "info", "repeater_id", "ts1", "cq", "ts1_info",
               "ts2", "ts2_info", "ref", "start", "hardware"]


def dmr_record(row):
    cells = row_cells(row, len(DMR_COLUMNS))
    if cells is None:
        return None
    record = dict(zip(DMR_COLUMNS, cells))
    # Plain callsigns, plus network names like "OE-MLINK" (no suffix to remove).
    record["callsign"] = callsign(record["callsign"])
    return record


def scrap_dmr_status_page(url, table):
    return scrap_status_page(url, table, dmr_record)
