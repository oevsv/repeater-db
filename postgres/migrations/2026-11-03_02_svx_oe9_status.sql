-- FM status from the SVXLink reflector OE9, added to api.network_status.
--
-- scrap_fm_svx_oe9: snapshots of the reflector's nodes with monitored
-- talkgroups (scraper scrap_fm_svx_oe9, JSON of https://svx.oe9hamnet.at/).
-- Same table as in scripts/create_scrap_tables.sql (IF NOT EXISTS: a fresh
-- setup gets it from there, an existing one from here).
--
-- api.svx_oe9_status: like api.oelink_status, one row per callsign ever listed:
--   callsign (without suffix: OE9XVV-R -> OE9XVV), network ('SVXLink OE9'),
--   text (empty: the node details are mostly defaults / dummies),
--   active (listed within the last 120 minutes), last_active (last listed).
-- Nodes of one callsign with different suffixes (OE9XDW-R, OE9XDW-SR) count as
-- one. Hotspots and links are listed too; the map only uses entries whose
-- callsign has an FM transmitter at a site.
--
-- api.network_status: plus SVXLink OE9 (technology fm); same columns, so
-- CREATE OR REPLACE keeps its grants.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-03_02_svx_oe9_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://svx.oe9hamnet.at/ (JSON: /reflector_proxy/)
CREATE TABLE IF NOT EXISTS public.scrap_fm_svx_oe9 (
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

CREATE INDEX IF NOT EXISTS scrap_fm_svx_oe9_callsign_ts_idx ON public.scrap_fm_svx_oe9 (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_fm_svx_oe9 TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_fm_svx_oe9_id_seq TO repeater_scrap;

CREATE VIEW api.svx_oe9_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS scraped_timestamp
          FROM public.scrap_fm_svx_oe9
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT callsign,
           'SVXLink OE9'::text AS network,
           ''::text AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.svx_oe9_status IS 'Live status of the FM nodes on the SVXLink reflector OE9 (active = listed within 120 minutes)';

CREATE OR REPLACE VIEW api.network_status AS
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.oelink_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.ipsc2_status
    UNION ALL
    SELECT callsign, network, 'c4fm'::text AS technology, text, active, last_active FROM api.ycs232_status
    UNION ALL
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.dcs009_status
    UNION ALL
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.xlx905_status
    UNION ALL
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.ircddb_status
    UNION ALL
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.svx_oe9_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2: DMR, YCS232: C4FM, DCS009/XLX905/ircDDB: D-STAR)';

GRANT SELECT ON api.svx_oe9_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
