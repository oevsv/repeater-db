# Scrapers

Collect the Austrian stations listed on other web pages (FM, DMR, D-STAR, C4FM, TETRA,
Winlink servers) into `scrap_*` tables of the vhf database. Every run appends a snapshot: all
rows of one run share the same `scraped_timestamp` (UTC).

| Scraper / table | Source |
|---|---|
| `scrap_c4fm_ycs232` | https://ycs232.oevsv.at/_status.html |
| `scrap_dmr_ipsc2` | https://ipsc2.oevsv.at/_status.html |
| `scrap_dmr_ipsc2_hotspot` | https://dmo.oevsv.at/_status.html |
| `scrap_dmr_brandmeister` | https://api.brandmeister.network/v2/device/byMaster/2322 (Brandmeister API; dashboard https://brandmeister.network/#/devices is WebSocket only; Austrian master, OE callsigns only) |
| `scrap_oelink` | https://oe-link.oevsv.at/_status.html |
| `scrap_fm_svx_oe9` | https://svx.oe9hamnet.at/ (SVXLink reflector OE9; its JSON `/reflector_proxy/`, only nodes with monitored talkgroups) |
| `scrap_dstar_dcs009` | https://xlx232.oevsv.at/_status.html |
| `scrap_dstar_xlx905` | http://xlx905.oevsv.at:8888/index.php?show=repeaters |
| `scrap_dstar_ircddb` | https://status.ircddb.net/cgi-bin/ircddb-gw?AUT |
| `scrap_dstar_ref096` | http://ref096.dstargateway.org/ (D-Plus reflector REF096: gateways linked right now, per module) |
| `scrap_dstar_ref` | https://dstarusers.org/repeaters.php (country Austria) |
| `scrap_tetra_oevsv` | http://tetra-reflector.dyndns.org/ (SVXReflector TETRA OE-MASTER; its table `create_html.php`, only gateways with monitored talkgroups) |
| `scrap_tetra_de` | http://leipzig2000.dyndns.org:4047/ (Tetra Dashboard of the DL/EA/CT TETRA SVXReflectors; its JSON `/api/status`, only OE nodes with monitored talkgroups) |
| `scrap_winlink_pactor` | https://cms.winlink.org:444/GatewayChannels.aspx (Pactor, OE only) |

Every table has a column `callsign`, upper case. Where a page lists a callsign only with
a suffix, the original is kept too and `callsign` has it without the suffix:
`scrap_dstar_xlx905.dv_station` `OE9XGV-B` → `OE9XGV`, `scrap_c4fm_ycs232.station`
`HB9DR-2` → `HB9DR`, `scrap_fm_svx_oe9.node` `OE9XVV-R` → `OE9XVV`, `scrap_tetra_oevsv.node` `OE1XCS-T` → `OE1XCS`, `scrap_dmr_brandmeister.device_callsign` `OE9XKV Dornbirn` → `OE9XKV`. Some entries are not callsigns (networks like `OE-MLINK`, C4FM rooms
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
| `ticket_mail.py`, `systemd/repeater-ticket-mail.service` | E-mail notifications for tickets, see [Ticket e-mails](#ticket-e-mails) (not a scraper) |

## Setup

```
apt install python3-requests python3-bs4 python3-psycopg    # or: pip install -r requirements.txt
sudo -u postgres psql vhf -f create_scrap_tables.sql         # DELETES data in existing scrap_* tables
```

`create_scrap_tables.sql` creates the tables (owner `vhf_owner`) and the role `repeater_scrap`, which
may only insert into them; run it as postgres, as it creates a role.

## Database login (password)

The scrapers log in as `repeater_scrap` with a password, over TCP:

```
# 1. Password for the role (prompted, so it stays out of the shell history)
sudo -u postgres psql -c '\password repeater_scrap'

# 2. pg_hba.conf on the database server: allow the role from the scrapers' address.
#    The first matching line wins: put it before more general "host" lines with
#    another method. Scrapers on the same machine: 127.0.0.1/32.
host  vhf  repeater_scrap  <address of the scraper machine>/32  scram-sha-256

# 3. Make PostgreSQL read pg_hba.conf again
systemctl reload postgresql
```

PostgreSQL must listen on the address the scrapers connect to (`listen_addresses` in
`postgresql.conf`; the default is localhost only).

`db_config.ini` (libpq parameter names; comments only on lines of their own):

```ini
[postgresql]
# PostgreSQL server; 127.0.0.1 if it runs on the same machine
host = 10.43.48.1
port = 5432
dbname = vhf
user = repeater_scrap
password = <the password set with \password>
```

It contains the password: keep it readable by root only. The service gets it as a
credential (see below); for runs by hand the scripts also look for it next to themselves
(gitignored).

Alternative without password, only if PostgreSQL runs on the same machine: `host =
/var/run/postgresql` and no `password`. That uses peer authentication on the local socket,
which requires the connecting system user to have the role's name (`repeater_scrap`, as
the service does).

## Run by hand

```
python3 scrap_all.py                                    # all scrapers
python3 scrap_all.py scrap_dmr_ipsc2 scrap_dstar_ref    # only these
```

The scripts can be started from any directory. `scrap_all.py` runs every scraper even if
some fail (site down, page layout changed, database error), prints a summary and exits with
status 1 if any failed, 0 otherwise (2 for an unknown scraper name). A page without the
expected rows counts as a failure, as it usually means its layout changed.

On the server, with the config of the service (as root):

```
CREDENTIALS_DIRECTORY=/etc/repeater-scrap python3 /opt/repeater-scrap/scrap_all.py scrap_oelink
```

## Service (systemd)

`repeater-scrap.service` runs `scrap_all.py` once, `repeater-scrap.timer` starts it hourly.
The service runs as the system user `repeater_scrap` and can't write anywhere. The database
config with the password stays root-only: systemd hands the service a private copy
(`LoadCredential=`).

```
# 0. System user
useradd --system --no-create-home --shell /usr/sbin/nologin repeater_scrap

# 1. Scripts (a copy of this directory; the service only reads it)
install -d /opt/repeater-scrap
cp *.py README.md /opt/repeater-scrap/

# 2. Tables and role (only once: deletes existing scraped data), then password and
#    pg_hba.conf, see "Database login" above
sudo -u postgres psql vhf -f create_scrap_tables.sql

# 3. Database config, root only
install -d -m 700 /etc/repeater-scrap
install -m 600 /dev/null /etc/repeater-scrap/db_config.ini
editor /etc/repeater-scrap/db_config.ini        # see "Database login" above

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
journalctl -u repeater-scrap.service -n 30 --no-pager -o cat   # output of the last runs
```

Update: copy the changed scripts to `/opt/repeater-scrap` again (no restart needed, every run
starts fresh). Another interval: `OnCalendar=` in the timer, then `systemctl daemon-reload`.

## Troubleshooting the database login

A failed login names the system user, the database role and the config file used. The
message from PostgreSQL says why:

| Message | Cause |
|---|---|
| `password authentication failed for user "repeater_scrap"` | Wrong password in `db_config.ini`, or none set (`\password repeater_scrap`) |
| `no pg_hba.conf entry for host "…", user "repeater_scrap", database "vhf"` | No `pg_hba.conf` line for that address, or PostgreSQL not reloaded |
| `Connection refused` / timeout | PostgreSQL doesn't listen on that address (`listen_addresses`), or a firewall |
| `Peer authentication failed for user "repeater_scrap"` | The config uses the local socket (`host = /var/run/postgresql`, or no `host` at all), not the password login |
| `permission denied for table scrap_…` | The role lacks its rights: run the grant part of `create_scrap_tables.sql` |
| `Database config … not found or not readable` | Config missing, or the service doesn't get it (`LoadCredential=` path) |

PostgreSQL logs the exact reason of a refused login in its own log
(`/var/log/postgresql/postgresql-*-main.log`).

## Adding a source

Add a function to `scrapers.py`: download the page with `get_soup()`, select the rows and
pass them to `save(table, rows, to_record)`, where `to_record(row)` returns a dict
`{column: value}` (or `None` to skip the row). Use `callsign()` / `base_callsign()` for the
callsign. Register the function in `SCRAPERS` and add its table to
`create_scrap_tables.sql`.

## Ticket e-mails

`ticket_mail.py` sends one mail per ticket message (website `/ticket`: the first text and
every reply) to the ticket's author (e-mail from the SSO login) with `ukw@oevsv.at` in Cc,
through the local mail server (SMTP on localhost:25). Reply-To is `ukw@oevsv.at`, and all
mails of one ticket are in one thread. The database announces new messages
(`NOTIFY ticket_mail`), so a mail goes out within seconds. The service also checks every
5 minutes, so a failed send (mail server down) is retried; the journal shows it.

```
# 0. Database: migration 2026-11-06_03_ticket_mail.sql (creates the role repeater_mail)
# 1. System user (same name as the role: peer login over the local socket, no password)
useradd --system --no-create-home --shell /usr/sbin/nologin repeater_mail
sudo -u repeater_mail psql -h /var/run/postgresql vhf -c 'SELECT count(*) FROM ticket'   # test the login
#    Fails with "Peer authentication failed": pg_hba.conf needs
#    local  vhf  repeater_mail  peer       (before other "local" lines), then reload postgresql
# 2. Script (in the scrapers' directory)
cp ticket_mail.py /opt/repeater-scrap/
# 3. Check what would be sent (nothing should be pending after the migration)
sudo -u repeater_mail env PGHOST=/var/run/postgresql PGDATABASE=vhf python3 /opt/repeater-scrap/ticket_mail.py --dry-run
# 4. Unit
cp systemd/repeater-ticket-mail.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now repeater-ticket-mail.service
```

Check: `journalctl -u repeater-ticket-mail.service -n 30 --no-pager -o cat` ("sent message
... to ..., cc ukw@oevsv.at"). "FAILED ..., retried later": temporary (mail server down
or busy), sent at the next check. "GAVE UP ...": rejected permanently (SMTP 5xx) or the
mail could not be built; the message is skipped (marked as mailed) so that it never
blocks the following ones; it stays readable on the web page. Unsent messages:
`psql vhf -c "SELECT created, ticket_id FROM ticket_message WHERE mailed IS NULL"`.

Sender: `ÖVSV Repeater <noreply@repeater.oevsv.at>`. Change it with
`Environment="TICKET_MAIL_FROM=..."` in the unit if the mail server needs another address.
The admin address is fixed in `ticket_mail.py` (`ADMIN`). Update: copy the script again,
then `systemctl restart repeater-ticket-mail`.
