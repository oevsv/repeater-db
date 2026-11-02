# Scrapers

Collect the Austrian stations listed on other web pages (DMR, D-STAR, C4FM, Winlink
servers) into `scrap_*` tables of the vhf database. Every run appends a snapshot: all
rows of one run share the same `scraped_timestamp` (UTC).

| Scraper / table | Source |
|---|---|
| `scrap_c4fm_ycs232` | https://ycs232.oevsv.at/_status.html |
| `scrap_dmr_ipsc2` | https://ipsc2.oevsv.at/_status.html |
| `scrap_dmr_ipsc2_hotspot` | https://dmo.oevsv.at/_status.html |
| `scrap_oelink` | https://oe-link.oevsv.at/_status.html |
| `scrap_dstar_dcs009` | https://xlx232.oevsv.at/_status.html |
| `scrap_dstar_xlx905` | http://xlx905.oevsv.at:8888/index.php?show=repeaters |
| `scrap_dstar_ircddb` | https://status.ircddb.net/cgi-bin/ircddb-gw?AUT |
| `scrap_dstar_ref` | https://dstarusers.org/repeaters.php (country Austria) |
| `scrap_winlink_pactor` | https://cms.winlink.org:444/GatewayChannels.aspx (Pactor, OE only) |

Every table has a column `callsign`, upper case. Where a page lists a callsign only with
a suffix, the original is kept too and `callsign` has it without the suffix:
`scrap_dstar_xlx905.dv_station` `OE9XGV-B` → `OE9XGV`, `scrap_c4fm_ycs232.station`
`HB9DR-2` → `HB9DR`. Some entries are not callsigns (networks like `OE-MLINK`, C4FM rooms
like `FCS22820`). The `scrap_*` tables are not part of the API.

## Files

| File | Content |
|---|---|
| `scrapers.py` | The sources: one short function per table (where the rows are, how a row maps to columns) |
| `scrap_common.py` | Shared code: download (15 s timeout), parsing helpers, callsign rules, storing |
| `scrap_all.py` | Runs the scrapers |
| `create_scrap_tables.sql` | Creates the tables (drops existing ones and their data) |
| `load_db_config.py` | Reads `db_config.ini` |
| `systemd/repeater-scrap.service`, `.timer` | Runs the scrapers hourly, see [Service](#service-systemd) |

## Setup

```
apt install python3-requests python3-bs4 python3-psycopg    # or: pip install -r requirements.txt
sudo -u postgres psql vhf -f create_scrap_tables.sql         # DELETES data in existing scrap_* tables
```

`create_scrap_tables.sql` creates the tables (owner `dz`) and the role `repeater_scrap`, which
may only insert into them; run it as postgres, as it creates a role.

Database connection: `db_config.ini` (libpq parameter names):

```ini
[postgresql]
host = /var/run/postgresql
dbname = vhf
user = repeater_scrap
# password = ...   (not needed for the local socket with peer authentication)
```

The scripts look for it in the directory systemd passes credentials in (see below), else
next to the scripts (gitignored).

## Run by hand

```
python3 scrap_all.py                                    # all scrapers
python3 scrap_all.py scrap_dmr_ipsc2 scrap_dstar_ref    # only these
```

The scripts can be started from any directory. `scrap_all.py` runs every scraper even if
some fail (site down, page layout changed, database error), prints a summary and exits with
status 1 if any failed, 0 otherwise (2 for an unknown scraper name). A page without the
expected rows counts as a failure, as it usually means its layout changed.

## Service (systemd)

`repeater-scrap.service` runs `scrap_all.py` once, `repeater-scrap.timer` starts it hourly.
The service runs as a temporary user `repeater_scrap` (`DynamicUser=`), which logs into
PostgreSQL over the local socket as the role of the same name (peer authentication, no
password). It can't write anywhere; the database config is passed in as a credential, so
it stays root-only.

```
# 1. Scripts (a copy of this directory; the service only reads it)
install -d /opt/repeater-scrap
cp *.py README.md /opt/repeater-scrap/

# 2. Database config, root only
install -d -m 700 /etc/repeater-scrap
install -m 600 /dev/null /etc/repeater-scrap/db_config.ini
editor /etc/repeater-scrap/db_config.ini        # see "Setup" above

# 3. Tables and role (only once: deletes existing scraped data)
sudo -u postgres psql vhf -f create_scrap_tables.sql

# 4. Units
cp systemd/repeater-scrap.service systemd/repeater-scrap.timer /etc/systemd/system/
systemctl daemon-reload
systemctl start repeater-scrap.service          # one run now, to test
systemctl enable --now repeater-scrap.timer     # then hourly
```

Check:
```
systemctl list-timers repeater-scrap.timer      # next run
systemctl status repeater-scrap.service         # last run: "failed" if a scraper failed
journalctl -u repeater-scrap.service            # output of the runs
```

Update: copy the changed scripts to `/opt/repeater-scrap` again (no restart needed, every run
starts fresh). Another interval: `OnCalendar=` in the timer, then `systemctl daemon-reload`.

## Adding a source

Add a function to `scrapers.py`: download the page with `get_soup()`, select the rows and
pass them to `save(table, rows, to_record)`, where `to_record(row)` returns a dict
`{column: value}` (or `None` to skip the row). Use `callsign()` / `base_callsign()` for the
callsign. Register the function in `SCRAPERS` and add its table to
`create_scrap_tables.sql`.
