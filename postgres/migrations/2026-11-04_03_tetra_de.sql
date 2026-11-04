-- TETRA status from the Tetra Dashboard http://leipzig2000.dyndns.org:4047/
-- ("Tetra-DE"), added to api.network_status and to the network links.
--
-- The dashboard (a React page) loads the JSON /api/status, which merges the
-- node lists of several TETRA SVXReflectors (DL, EA, CT). The scraper stores
-- only Austrian nodes (OE callsign) with monitored talkgroups.
--
-- scrap_tetra_de: snapshots of those nodes (scraper scrap_tetra_de); node
-- with suffix ("OE9XFV-R"), callsign without. Same table as in
-- scripts/create_scrap_tables.sql (IF NOT EXISTS).
--
-- api.tetra_de_status: like api.svx_oe9_status, one row per callsign, network
-- 'Tetra-DE', no text, active = listed within the last 120 minutes.
--
-- Network 'tetra_de' (TETRA only: the callsign rule of the automatic fill
-- links a node to the callsign's only TETRA transmitter).
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-04_03_tetra_de.sql
-- then link:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- http://leipzig2000.dyndns.org:4047/ (JSON /api/status; OE nodes only)
CREATE TABLE IF NOT EXISTS public.scrap_tetra_de (
    id SERIAL PRIMARY KEY,
    callsign TEXT,       -- node without suffix: OE9XFV
    node TEXT,           -- as listed: OE9XFV-R
    monitored_tgs TEXT,  -- blank separated: "91 228 232"
    source_tag TEXT,     -- reflector the dashboard got it from: DL, EA, CT
    node_location TEXT,  -- empty if the SVXLink default
    tx_freq TEXT,        -- first transmitter, MHz; empty if the default 433.45
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_tetra_de_callsign_ts_idx
    ON public.scrap_tetra_de (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_tetra_de TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_tetra_de_id_seq TO repeater_scrap;

CREATE VIEW api.tetra_de_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS scraped_timestamp
          FROM public.scrap_tetra_de
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT callsign,
           'Tetra-DE'::text AS network,
           ''::text AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.tetra_de_status IS 'Live status of the Austrian TETRA nodes on the reflectors of the Tetra Dashboard leipzig2000 (active = listed within 120 minutes)';

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
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.brandmeister_status
    UNION ALL
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.ref096_status
    UNION ALL
    SELECT callsign, network, 'tetra'::text AS technology, text, active, last_active FROM api.tetra_de_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV, Tetra-DE: TETRA)';

GRANT SELECT ON api.tetra_de_status TO web_anon;

-- --- network links ------------------------------------------------------------

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('tetra_de', 'Tetra-DE', 'http://leipzig2000.dyndns.org:4047/', '{tetra}', 85);

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

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
