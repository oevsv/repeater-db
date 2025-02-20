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