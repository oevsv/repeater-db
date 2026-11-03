-- Tables of the scrapers (scripts/scrapers.py), one per scraped source. Every
-- run appends a snapshot: all rows of one run share the same scraped_timestamp
-- (UTC). Texts are stored as shown on the pages, except:
--   callsign    always present, upper case (OE7XBI). Where a page shows the
--               callsign only with a suffix, the original is kept as well
--               (dv_station "OE9XGV-B", station "HB9DR-2") and callsign has
--               it without the suffix (OE9XGV, HB9DR).
--
-- Also creates the role repeater_scrap the scrapers log in as (systemd
-- service repeater-scrap), allowed to INSERT into these tables only. Its
-- password and pg_hba.conf entry are set up separately, see README.md
-- "Database login". The tables are owned by vhf_owner.
--
-- Drops and recreates the tables: ALL SCRAPED DATA IS DELETED.
-- Run as postgres (creates a role):  sudo -u postgres psql vhf -f create_scrap_tables.sql

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'repeater_scrap') THEN
        CREATE ROLE repeater_scrap LOGIN;
    END IF;
END
$$;

DROP TABLE IF EXISTS scrap_c4fm_ycs232, scrap_dmr_ipsc2, scrap_dmr_ipsc2_hotspot, scrap_oelink,
    scrap_fm_svx_oe9, scrap_dstar_dcs009, scrap_dstar_xlx905, scrap_dstar_ircddb, scrap_dstar_ref,
    scrap_winlink_pactor;

-- C4FM: https://ycs232.oevsv.at/_status.html
CREATE TABLE scrap_c4fm_ycs232 (
    id SERIAL PRIMARY KEY,
    nr TEXT,
    callsign TEXT,     -- station without suffix: HB9DR, FCS22820, BM2322, DVMATRIX
    station TEXT,      -- as listed: HB9DR-2, FCS22820  -335555, BM2322-AT, DVMatrix
    group_code TEXT,
    name TEXT,
    qrg TEXT,
    repeater_id TEXT,
    dg_id TEXT,
    name2 TEXT,
    rx_tx TEXT,
    mode TEXT,
    type TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.ycs232_status reads the latest row per callsign (migration 2026-11-02_05_ycs232_status.sql).
CREATE INDEX scrap_c4fm_ycs232_callsign_ts_idx ON scrap_c4fm_ycs232 (callsign, scraped_timestamp DESC);

-- DMR, all three with the same columns; callsign also holds network names (OE-MLINK).
-- https://ipsc2.oevsv.at/_status.html
CREATE TABLE scrap_dmr_ipsc2 (
    id SERIAL PRIMARY KEY,
    nr TEXT,
    callsign TEXT,
    info TEXT,
    repeater_id TEXT,
    ts1 TEXT,
    cq TEXT,
    ts1_info TEXT,
    ts2 TEXT,
    ts2_info TEXT,
    ref TEXT,
    start TEXT,
    hardware TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.ipsc2_status reads the latest row per callsign (migration 2026-11-02_04_ipsc2_network_status.sql).
CREATE INDEX scrap_dmr_ipsc2_callsign_ts_idx ON scrap_dmr_ipsc2 (callsign, scraped_timestamp DESC);

-- https://dmo.oevsv.at/_status.html
CREATE TABLE scrap_dmr_ipsc2_hotspot (
    id SERIAL PRIMARY KEY,
    nr TEXT,
    callsign TEXT,
    info TEXT,
    repeater_id TEXT,
    ts1 TEXT,
    cq TEXT,
    ts1_info TEXT,
    ts2 TEXT,
    ts2_info TEXT,
    ref TEXT,
    start TEXT,
    hardware TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- https://oe-link.oevsv.at/_status.html
CREATE TABLE scrap_oelink (
    id SERIAL PRIMARY KEY,
    nr TEXT,
    callsign TEXT,
    info TEXT,
    repeater_id TEXT,
    ts1 TEXT,
    cq TEXT,
    ts1_info TEXT,
    ts2 TEXT,
    ts2_info TEXT,
    ref TEXT,
    start TEXT,
    hardware TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.oelink_status reads the latest row per callsign (migration 2026-11-02_03_oelink_status.sql).
CREATE INDEX scrap_oelink_callsign_ts_idx ON scrap_oelink (callsign, scraped_timestamp DESC);

-- FM: SVXLink reflector OE9, https://svx.oe9hamnet.at/ (JSON: /reflector_proxy/);
-- only nodes with monitored talkgroups.
CREATE TABLE scrap_fm_svx_oe9 (
    id SERIAL PRIMARY KEY,
    callsign TEXT,       -- node without suffix: OE9XVV
    node TEXT,           -- as listed: OE9XVV-R, OE9KHJ-HS
    monitored_tgs TEXT,  -- blank separated: "20 232 2329"
    node_location TEXT,
    sysop TEXT,
    tx_freq TEXT,
    tx_name TEXT,
    tx_pwr TEXT,
    lat TEXT,
    long TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.svx_oe9_status reads the latest row per callsign (migration 2026-11-03_02_svx_oe9_status.sql).
CREATE INDEX scrap_fm_svx_oe9_callsign_ts_idx ON scrap_fm_svx_oe9 (callsign, scraped_timestamp DESC);

-- D-STAR DCS009: https://xlx232.oevsv.at/_status.html
CREATE TABLE scrap_dstar_dcs009 (
    id SERIAL PRIMARY KEY,
    nr TEXT,
    callsign TEXT,
    band TEXT,
    linked TEXT,
    dcs_group TEXT,
    via TEXT,
    software TEXT,
    hb_timer TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.*_status read the latest row per callsign (migration 2026-11-02_06_dstar_status.sql).
CREATE INDEX scrap_dstar_dcs009_callsign_ts_idx ON scrap_dstar_dcs009 (callsign, scraped_timestamp DESC);

-- D-STAR XLX905: http://xlx905.oevsv.at:8888/index.php?show=repeaters
CREATE TABLE scrap_dstar_xlx905 (
    id SERIAL PRIMARY KEY,
    no TEXT,
    flag TEXT,
    callsign TEXT,     -- dv_station without the module suffix: OE9XGV
    dv_station TEXT,   -- as listed: OE9XGV-B
    band TEXT,
    last_heard TEXT,
    linked_for TEXT,
    protocol TEXT,
    module TEXT,
    ip_address TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.*_status read the latest row per callsign (migration 2026-11-02_06_dstar_status.sql).
CREATE INDEX scrap_dstar_xlx905_callsign_ts_idx ON scrap_dstar_xlx905 (callsign, scraped_timestamp DESC);

-- D-STAR ircDDB gateways: https://status.ircddb.net/cgi-bin/ircddb-gw?AUT
CREATE TABLE scrap_dstar_ircddb (
    id SERIAL PRIMARY KEY,
    callsign TEXT,
    status TEXT,       -- Online / Offline
    country TEXT,      -- ISO 3166 alpha-3, e.g. AUT
    scraped_timestamp TIMESTAMP NOT NULL
);

-- api.*_status read the latest row per callsign (migration 2026-11-02_06_dstar_status.sql).
CREATE INDEX scrap_dstar_ircddb_callsign_ts_idx ON scrap_dstar_ircddb (callsign, scraped_timestamp DESC);

-- D-STAR REF: https://dstarusers.org/repeaters.php (country Austria)
CREATE TABLE scrap_dstar_ref (
    id SERIAL PRIMARY KEY,
    callsign TEXT,
    city TEXT,
    state TEXT,
    freq_2m TEXT,
    freq_70cm TEXT,
    freq_23cm TEXT,
    freq_23cmdd TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- Winlink Pactor gateways (OE only): https://cms.winlink.org:444/GatewayChannels.aspx
CREATE TABLE scrap_winlink_pactor (
    id SERIAL PRIMARY KEY,
    posted TEXT,
    callsign TEXT,
    grid_square TEXT,
    frequency TEXT,
    mode TEXT,
    hours TEXT,
    qth TEXT,
    scraped_timestamp TIMESTAMP NOT NULL
);

-- Owner vhf_owner like the rest of the schema; the scrapers may only add rows.
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['scrap_c4fm_ycs232', 'scrap_dmr_ipsc2', 'scrap_dmr_ipsc2_hotspot',
            'scrap_oelink', 'scrap_fm_svx_oe9', 'scrap_dstar_dcs009', 'scrap_dstar_xlx905', 'scrap_dstar_ircddb',
            'scrap_dstar_ref', 'scrap_winlink_pactor'] LOOP
        EXECUTE format('ALTER TABLE %I OWNER TO vhf_owner', t);
        EXECUTE format('GRANT INSERT ON %I TO repeater_scrap', t);
        EXECUTE format('GRANT USAGE ON SEQUENCE %I TO repeater_scrap', t || '_id_seq');
    END LOOP;
END
$$;

COMMIT;
