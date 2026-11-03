-- DMR status from Brandmeister, added to api.network_status and to the
-- network links (trx.networks).
--
-- scrap_dmr_brandmeister: snapshots of the devices (repeaters, hotspots) with
-- an Austrian callsign on the Brandmeister master 2322 (scraper
-- scrap_dmr_brandmeister, Brandmeister API v2 /device/byMaster/2322). Same
-- table as in scripts/create_scrap_tables.sql (IF NOT EXISTS).
--
-- api.brandmeister_status: like api.ipsc2_status, one row per callsign:
--   callsign (without the place some devices add: "OE9XKV Dornbirn" -> OE9XKV),
--   network ('Brandmeister'), text (device ID and hardware, e.g.
--   "232078 R10QCGANQ1AN"), active (Brandmeister saw the device within the last
--   120 minutes), last_active (last seen). A callsign with several devices
--   (OE8XGK: 232072, 232836): the one seen last. Unlike the other networks the
--   time comes from Brandmeister's last_seen, not from the scrape: the API
--   lists devices for about a month after they were last on the air.
--
-- api.network_status: plus Brandmeister (technology dmr); same columns, so
-- CREATE OR REPLACE keeps its grants.
--
-- Network links: network 'brandmeister' (node = device ID, so the automatic
-- fill links repeaters by trx.digital_id), api.network_node plus its devices.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-03_05_brandmeister.sql
-- then link the Brandmeister repeaters:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://api.brandmeister.network/v2/device/byMaster/2322, OE callsigns only
CREATE TABLE IF NOT EXISTS public.scrap_dmr_brandmeister (
    id SERIAL PRIMARY KEY,
    callsign TEXT,         -- without a place: OE9XKV
    device_id TEXT,        -- Brandmeister / DMR ID: 232078 (repeater), 2320001 (hotspot)
    device_callsign TEXT,  -- as listed: "OE9XKV Dornbirn"
    status TEXT,           -- Brandmeister device status code (2, 3, 4; not documented)
    last_seen TIMESTAMP,   -- UTC, when Brandmeister last saw the device
    tx TEXT,
    rx TEXT,
    colorcode TEXT,
    hardware TEXT,
    firmware TEXT,
    city TEXT,
    lat TEXT,
    lng TEXT,
    master TEXT,           -- lastKnownMaster
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_dmr_brandmeister_callsign_ts_idx
    ON public.scrap_dmr_brandmeister (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_dmr_brandmeister TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_dmr_brandmeister_id_seq TO repeater_scrap;

CREATE VIEW api.brandmeister_status AS
    WITH device AS (  -- latest listing per device
        SELECT DISTINCT ON (device_id) callsign, device_id, hardware, last_seen
          FROM public.scrap_dmr_brandmeister
         WHERE coalesce(callsign, '') <> '' AND last_seen IS NOT NULL
         ORDER BY device_id, scraped_timestamp DESC
    ), latest AS (    -- per callsign the device seen last
        SELECT DISTINCT ON (callsign) callsign, device_id, hardware, last_seen
          FROM device
         ORDER BY callsign, last_seen DESC
    )
    SELECT callsign,
           'Brandmeister'::text AS network,
           concat_ws(' ', nullif(device_id, ''), nullif(hardware, '')) AS text,
           (last_seen AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           last_seen AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.brandmeister_status IS 'Live status of the Austrian DMR devices on Brandmeister (active = seen by Brandmeister within 120 minutes)';

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
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.svx_oe9_status
    UNION ALL
    SELECT callsign, network, 'tetra'::text AS technology, text, active, last_active FROM api.tetra_oevsv_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.brandmeister_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/ircDDB: D-STAR, Tetra ÖVSV: TETRA)';

GRANT SELECT ON api.brandmeister_status TO web_anon;

-- --- network links ------------------------------------------------------------

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('brandmeister', 'Brandmeister', 'https://brandmeister.network/#/devices', '{dmr}', 35);

CREATE OR REPLACE VIEW api.network_node AS
    SELECT network_id, node, callsign,
           max(scraped_timestamp) AT TIME ZONE 'UTC' AS last_listed,
           (array_agg(frequency ORDER BY scraped_timestamp DESC))[1] AS frequency
      FROM (SELECT 'oelink' AS network_id, repeater_id AS node, callsign, scraped_timestamp,
                   NULL::numeric AS frequency FROM public.scrap_oelink
            UNION ALL
            SELECT 'svx_oe9' AS network_id, node, callsign, scraped_timestamp,
                   CASE WHEN tx_freq ~ '^\d+(\.\d+)?$' THEN tx_freq::numeric END AS frequency FROM public.scrap_fm_svx_oe9
            UNION ALL
            SELECT 'ipsc2' AS network_id, repeater_id AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dmr_ipsc2
            UNION ALL
            SELECT 'ycs232' AS network_id, station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_c4fm_ycs232
            UNION ALL
            SELECT 'dcs009' AS network_id, callsign AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dstar_dcs009
            UNION ALL
            SELECT 'xlx905' AS network_id, dv_station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dstar_xlx905
            UNION ALL
            SELECT 'ircddb' AS network_id, callsign AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dstar_ircddb
            UNION ALL
            -- Brandmeister lists devices for about a month after they were last
            -- on the air: "listed" is when Brandmeister last saw the device.
            SELECT 'brandmeister' AS network_id, device_id AS node, callsign, last_seen AS scraped_timestamp,
                   CASE WHEN tx ~ '^\d+(\.\d+)?$' AND tx::numeric > 0 THEN tx::numeric END AS frequency
              FROM public.scrap_dmr_brandmeister
            UNION ALL
            SELECT 'tetra_oevsv' AS network_id, node, callsign, scraped_timestamp,
                   substring(comment FROM '/(\d+(?:\.\d+)?)\s*$')::numeric AS frequency FROM public.scrap_tetra_oevsv) n
     WHERE coalesce(node, '') <> ''
     GROUP BY network_id, node, callsign;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
