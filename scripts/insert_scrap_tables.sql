CREATE TABLE scrap_dstar_ref (
id SERIAL PRIMARY KEY,
callsign TEXT NOT NULL,
city TEXT NOT NULL,
state TEXT,
freq_2m TEXT,
freq_70cm TEXT,
freq_23cm TEXT,
freq_23cmdd TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE scrap_dstar_dcs009 (
id SERIAL PRIMARY KEY,
nr TEXT,
dv_station TEXT,
band TEXT,
linked TEXT,
dcs_group TEXT,
via TEXT,
software TEXT,
hb_timer TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE scrap_dstar_xlx905 (
id SERIAL PRIMARY KEY,
no            TEXT,
flag          TEXT,
dv_station    TEXT,
band          TEXT,
last_heard    TEXT,
linked_for    TEXT,
protocol      TEXT,
module        TEXT,
ip_address    TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE scrap_dstar_ircddb (
id SERIAL PRIMARY KEY,
callsign TEXT,
status TEXT,
country TEXT,
last_heard TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);

CREATE TABLE scrap_oelink (
id SERIAL PRIMARY KEY,
nr              TEXT,
repeater        TEXT,
info            TEXT,
repeater_id     TEXT,
ts1             TEXT,
cq              TEXT,
ts1_info        TEXT,
ts2             TEXT,
ts2_info        TEXT,
ref             TEXT,
start           TEXT,
hardware        TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE scrap_dmr_ipsc2 (
id SERIAL PRIMARY KEY,
nr              TEXT,
repeater        TEXT,
info            TEXT,
repeater_id     TEXT,
ts1             TEXT,
cq              TEXT,
ts1_info        TEXT,
ts2             TEXT,
ts2_info        TEXT,
ref             TEXT,
start           TEXT,
hardware        TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE scrap_dmr_ipsc2_hotspot (
id SERIAL PRIMARY KEY,
nr              TEXT,
repeater        TEXT,
info            TEXT,
repeater_id     TEXT,
ts1             TEXT,
cq              TEXT,
ts1_info        TEXT,
ts2             TEXT,
ts2_info        TEXT,
ref             TEXT,
start           TEXT,
hardware        TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);

CREATE TABLE scrap_c4fm_ycs232 (
id SERIAL PRIMARY KEY,
nr             TEXT,
callsign       TEXT,
group_code     TEXT,
name           TEXT,
qrg            TEXT,
repeater_id    TEXT,
dg_id          TEXT,
name2          TEXT,
rx_tx          TEXT,
mode           TEXT,
type           TEXT,
scraped_timestamp TIMESTAMP NOT NULL
)

-- scrap_winlink_gateways_init.sql
CREATE TABLE scrap_winlink_pactor (
    id SERIAL PRIMARY KEY,
    posted TEXT,
    callsign TEXT,
    grid_square TEXT,
    frequency TEXT,
    mode TEXT,
    hours TEXT,
    qth TEXT,
    contact_name TEXT,
    contact_email TEXT,
    contact_address TEXT,
    contact_phone TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);