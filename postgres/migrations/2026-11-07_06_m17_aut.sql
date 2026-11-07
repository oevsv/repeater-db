-- M17 status from the reflector M17-AUT (dashboard https://m17-aut.xreflector.net/,
-- page "Links": same layout as the XLX905 dashboard), added to
-- api.network_status and to the network links. New technology 'm17'.
--
-- scrap_m17_aut: snapshots of the linked stations; only Austrian callsigns
-- ("OE" + digit), stored by the scraper scrap_m17_aut. dv_station as listed
-- ("OE5HOO-D"), callsign without the suffix. Same table as in
-- scripts/create_scrap_tables.sql (IF NOT EXISTS).
-- api.m17_aut_status: one row per callsign, network 'M17 AT', text = the
-- stations as listed with their module ("OE3XOR-R B"), active = linked
-- within the last 120 minutes.
-- network 'm17_aut' ('M17 AT', technology m17; network_technologies_check
-- allows m17).
-- trx_technologies(): also 'm17' for transmitters with other_mode_name 'M17'
-- (there is no M17 flag), so the automatic fill can link them by callsign.
--
-- Apply before the new scraper runs (it inserts into the table), as dz or postgres:
--   psql vhf -f 2026-11-07_06_m17_aut.sql
-- then, after a scraper run, link:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://m17-aut.xreflector.net/index.php?show=links
CREATE TABLE IF NOT EXISTS public.scrap_m17_aut (
    id SERIAL PRIMARY KEY,
    no TEXT,
    flag TEXT,
    callsign TEXT,     -- dv_station without the suffix: OE5HOO
    dv_station TEXT,   -- as listed: OE5HOO-D
    via TEXT,          -- "DV Client" or empty
    last_heard TEXT,
    linked_for TEXT,
    protocol TEXT,
    module TEXT,       -- reflector module: B
    ip_address TEXT,   -- as shown (masked)
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_m17_aut_callsign_ts_idx
    ON public.scrap_m17_aut (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_m17_aut TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_m17_aut_id_seq TO repeater_scrap;

CREATE VIEW api.m17_aut_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS ts
          FROM public.scrap_m17_aut
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'M17 AT'::text AS network,
           (SELECT string_agg(DISTINCT concat_ws(' ', nullif(x.dv_station, ''), nullif(x.module, '')), ', ')
              FROM public.scrap_m17_aut x
             WHERE x.callsign = l.callsign AND x.scraped_timestamp = l.ts) AS text,
           (l.ts AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.ts AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

COMMENT ON VIEW api.m17_aut_status IS 'Live status of the Austrian stations linked to the M17 reflector M17-AUT (active = linked within 120 minutes)';

GRANT SELECT ON api.m17_aut_status TO web_anon;

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
    SELECT callsign, network, 'tetra'::text AS technology, text, active, last_active FROM api.tetra_de_status
    UNION ALL
    SELECT callsign, network, 'm17'::text AS technology, text, active, last_active FROM api.m17_aut_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, IPSC2 DE, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV, Tetra-DE: TETRA, M17 AT: M17)';

-- Known technologies: also m17.
ALTER TABLE public.network DROP CONSTRAINT network_technologies_check;
ALTER TABLE public.network ADD CONSTRAINT network_technologies_check
    CHECK (technologies <@ ARRAY['fm', 'dmr', 'c4fm', 'dstar', 'tetra', 'm17'] AND technologies <> '{}');

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('m17_aut', 'M17 AT', 'https://m17-aut.xreflector.net/', '{m17}', 90);

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
                   CASE WHEN tx_freq ~ '^\d+(\.\d+)?$' THEN tx_freq::numeric END AS frequency FROM public.scrap_tetra_de
            UNION ALL
            SELECT 'm17_aut' AS network_id, dv_station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_m17_aut) n
     WHERE coalesce(node, '') <> ''
     GROUP BY network_id, node, callsign;

-- The transmitter's modes: {fm}, {dmr}, {dmr,fm}, ... (order as on the website);
-- 'm17' from other_mode_name (no flag for M17).
CREATE OR REPLACE FUNCTION public.trx_technologies(t public.trx) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_remove(ARRAY[CASE WHEN t.fm THEN 'fm' END, CASE WHEN t.dmr THEN 'dmr' END,
                            CASE WHEN t.c4fm THEN 'c4fm' END, CASE WHEN t.dstar THEN 'dstar' END,
                            CASE WHEN t.tetra THEN 'tetra' END,
                            CASE WHEN upper(btrim(t.other_mode_name::text)) = 'M17' THEN 'm17' END], NULL)
$$;

COMMIT;
