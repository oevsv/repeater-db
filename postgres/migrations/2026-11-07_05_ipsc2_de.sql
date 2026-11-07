-- DMR status from IPSC2 DE (https://ipsc2-dl-rptr.xreflector.net/, the German
-- IPSC2 repeater server; same dashboard software as the ÖVSV IPSC2), added to
-- api.network_status and to the network links. Only Austrian stations: the
-- scraper (scrap_dmr_ipsc2_de) stores callsigns "OE<digit>..." only, not the
-- German repeaters and not the network names (OE-MLINK).
--
-- scrap_dmr_ipsc2_de: snapshots, same columns as scrap_dmr_ipsc2. Same table
-- as in scripts/create_scrap_tables.sql (IF NOT EXISTS).
-- api.ipsc2_de_status: as api.ipsc2_status, network 'IPSC2 DE'.
-- network 'ipsc2_de' ('IPSC2 DE', dmr): nodes are the repeater ids, linked by
-- trx_networks_autofill like IPSC2.
--
-- Apply before the new scraper runs (it inserts into the table), as dz or postgres:
--   psql vhf -f 2026-11-07_05_ipsc2_de.sql
-- then, after a scraper run, link:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://ipsc2-dl-rptr.xreflector.net/_status.html
CREATE TABLE IF NOT EXISTS public.scrap_dmr_ipsc2_de (
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

CREATE INDEX IF NOT EXISTS scrap_dmr_ipsc2_de_callsign_ts_idx
    ON public.scrap_dmr_ipsc2_de (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_dmr_ipsc2_de TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_dmr_ipsc2_de_id_seq TO repeater_scrap;

CREATE VIEW api.ipsc2_de_status AS
    WITH latest AS (
        SELECT DISTINCT ON (callsign) callsign, repeater_id, hardware, scraped_timestamp
          FROM public.scrap_dmr_ipsc2_de
         WHERE coalesce(callsign, '') <> ''
         ORDER BY callsign, scraped_timestamp DESC
    )
    SELECT callsign,
           'IPSC2 DE'::text AS network,
           concat_ws(' ', nullif(repeater_id, ''), nullif(hardware, '')) AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.ipsc2_de_status IS 'Live status of the Austrian repeaters on IPSC2 DE (active = listed within 120 minutes)';

GRANT SELECT ON api.ipsc2_de_status TO web_anon;

CREATE OR REPLACE VIEW api.network_status AS
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.oelink_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.ipsc2_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.ipsc2_de_status
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
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.brandmeister_status
    UNION ALL
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.ref096_status
    UNION ALL
    SELECT callsign, network, 'tetra'::text AS technology, text, active, last_active FROM api.tetra_de_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, IPSC2 DE, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV, Tetra-DE: TETRA)';

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('ipsc2_de', 'IPSC2 DE', 'https://ipsc2-dl-rptr.xreflector.net/', '{dmr}', 32);

CREATE OR REPLACE VIEW api.network_node AS
    SELECT network_id, node, callsign,
           max(scraped_timestamp) AT TIME ZONE 'UTC' AS last_listed,
           (array_agg(frequency ORDER BY scraped_timestamp DESC))[1] AS frequency,
           -- ircDDB: the latest listing says Offline (the gateway was online before)
           CASE WHEN network_id = 'ircddb'
                THEN coalesce((SELECT s.status FROM public.scrap_dstar_ircddb s
                                WHERE s.callsign = n.node ORDER BY s.scraped_timestamp DESC LIMIT 1) = 'Offline', false)
                ELSE false END AS offline
      FROM (SELECT 'oelink' AS network_id, repeater_id AS node, callsign, scraped_timestamp,
                   NULL::numeric AS frequency FROM public.scrap_oelink
            UNION ALL
            SELECT 'svx_oe9' AS network_id, node, callsign, scraped_timestamp,
                   CASE WHEN tx_freq ~ '^\d+(\.\d+)?$' THEN tx_freq::numeric END AS frequency FROM public.scrap_fm_svx_oe9
            UNION ALL
            SELECT 'ipsc2' AS network_id, repeater_id AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dmr_ipsc2
            UNION ALL
            SELECT 'ipsc2_de' AS network_id, repeater_id AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dmr_ipsc2_de
            UNION ALL
            SELECT 'ycs232' AS network_id, station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_c4fm_ycs232
            UNION ALL
            SELECT 'dcs009' AS network_id, callsign AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dstar_dcs009
            UNION ALL
            SELECT 'xlx905' AS network_id, dv_station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_dstar_xlx905
            UNION ALL
            -- ircDDB also lists gateways that are offline: only Online counts.
            SELECT 'ircddb' AS network_id, callsign AS node, callsign, scraped_timestamp, NULL::numeric AS frequency
              FROM public.scrap_dstar_ircddb WHERE status = 'Online'
            UNION ALL
            SELECT 'ref096' AS network_id, node, callsign, scraped_timestamp, NULL::numeric AS frequency
              FROM public.scrap_dstar_ref096
            UNION ALL
            -- Brandmeister lists devices for about a month after they were last
            -- on the air: "listed" is when Brandmeister last saw the device.
            SELECT 'brandmeister' AS network_id, device_id AS node, callsign, last_seen AS scraped_timestamp,
                   CASE WHEN tx ~ '^\d+(\.\d+)?$' AND tx::numeric > 0 THEN tx::numeric END AS frequency
              FROM public.scrap_dmr_brandmeister
            UNION ALL
            SELECT 'tetra_oevsv' AS network_id, node, callsign, scraped_timestamp,
                   substring(comment FROM '/(\d+(?:\.\d+)?)\s*$')::numeric AS frequency FROM public.scrap_tetra_oevsv
            UNION ALL
            SELECT 'tetra_de' AS network_id, node, callsign, scraped_timestamp,
                   CASE WHEN tx_freq ~ '^\d+(\.\d+)?$' THEN tx_freq::numeric END AS frequency FROM public.scrap_tetra_de) n
     WHERE coalesce(node, '') <> ''
     GROUP BY network_id, node, callsign;

COMMIT;
