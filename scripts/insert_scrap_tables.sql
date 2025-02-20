CREATE TABLE dstar_ref (
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


CREATE TABLE dstart_dcs009 (
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


CREATE TABLE dstar_xlx905 (
id SERIAL PRIMARY KEY,
num TEXT,
flag TEXT,
dv_station TEXT,
band TEXT,
last_heard TEXT,
linked_for TEXT,
protocol TEXT,
module TEXT,
ip TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);


CREATE TABLE dstar_ircddb (
id SERIAL PRIMARY KEY,
callsign TEXT,
status TEXT,
country TEXT,
last_heard TEXT,
scraped_timestamp TIMESTAMP NOT NULL
);