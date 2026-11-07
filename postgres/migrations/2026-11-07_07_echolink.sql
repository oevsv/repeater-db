-- EchoLink: the Austrian links (repeaters -R, simplex links -L) online at
-- EchoLink (https://www.echolink.org/links.jsp), added to api.network_status
-- and to the network links.
--
-- scrap_echolink: snapshots, only Austrian callsigns ("OE" + digit), stored
-- by the scraper scrap_echolink (a worldwide list; it loads only the pages
-- with the OE callsigns). station as listed ("OE1XCS-R"), callsign without
-- the suffix, node_number = the EchoLink node (= trx.echolink_id). Same
-- table as in scripts/create_scrap_tables.sql (IF NOT EXISTS).
-- api.echolink_status: one row per callsign, network 'Echolink', text = the
-- stations with node number ("OE1XCS-R 902425"), active = listed within the
-- last 120 minutes (the list only has links that are online).
-- network 'echolink' ('Echolink', fm): nodes are the node numbers.
-- trx_networks_autofill(): rule 'echolink_id' - an EchoLink node goes to the
-- transmitter with that trx.echolink_id (without checking the modes).
--
-- Apply before the new scraper runs (it inserts into the table), as dz or postgres:
--   psql vhf -f 2026-11-07_07_echolink.sql
-- then, after a scraper run, link:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://www.echolink.org/links.jsp (Online only), OE callsigns only
CREATE TABLE IF NOT EXISTS public.scrap_echolink (
    id SERIAL PRIMARY KEY,
    callsign TEXT,      -- station without the suffix: OE1XCS
    station TEXT,       -- as listed: OE1XCS-R (repeater) or OE7ABH-L (simplex link)
    description TEXT,
    node_number TEXT,   -- EchoLink node: 902425 (= trx.echolink_id)
    lat_lon TEXT,
    grid_square TEXT,
    place TEXT,
    frequency TEXT,     -- MHz, as entered by the sysop
    tone TEXT,
    power TEXT,
    haat TEXT,
    antenna TEXT,
    status TEXT,        -- Online, Conn (connected to another node)
    comment TEXT,
    last_update TEXT,   -- UTC, as listed
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_echolink_callsign_ts_idx
    ON public.scrap_echolink (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_echolink TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_echolink_id_seq TO repeater_scrap;

CREATE VIEW api.echolink_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS ts
          FROM public.scrap_echolink
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'Echolink'::text AS network,
           (SELECT string_agg(DISTINCT concat_ws(' ', nullif(x.station, ''), nullif(x.node_number, '')), ', ')
              FROM public.scrap_echolink x
             WHERE x.callsign = l.callsign AND x.scraped_timestamp = l.ts) AS text,
           (l.ts AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.ts AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

COMMENT ON VIEW api.echolink_status IS 'Live status of the Austrian EchoLink links (active = online within 120 minutes)';

GRANT SELECT ON api.echolink_status TO web_anon;

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
    SELECT callsign, network, 'm17'::text AS technology, text, active, last_active FROM api.m17_aut_status
    UNION ALL
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.echolink_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9, Echolink: FM, IPSC2, IPSC2 DE, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV, Tetra-DE: TETRA, M17 AT: M17)';

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('echolink', 'Echolink', 'https://www.echolink.org/links.jsp', '{fm}', 25);

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
            SELECT 'm17_aut' AS network_id, dv_station AS node, callsign, scraped_timestamp, NULL::numeric AS frequency FROM public.scrap_m17_aut
            UNION ALL
            -- EchoLink: node = node number (trx.echolink_id); frequency as entered by the sysop.
            SELECT 'echolink' AS network_id, node_number AS node, callsign, scraped_timestamp,
                   CASE WHEN frequency ~ '^\d+(\.\d+)?$' AND frequency::numeric > 0 THEN frequency::numeric END AS frequency
              FROM public.scrap_echolink) n
     WHERE coalesce(node, '') <> ''
     GROUP BY network_id, node, callsign;

CREATE OR REPLACE FUNCTION public.trx_networks_autofill(dry_run boolean DEFAULT true, max_age interval DEFAULT '30 days')
    RETURNS TABLE (network_id text, node text, trx_uid bigint, site_name text, callsign text,
                   frequency_tx double precision, rule text)
    LANGUAGE sql
    AS $$
  WITH nodes AS (
         SELECT nn.network_id, nn.node, nn.callsign, nn.last_listed, nn.frequency, n.technologies
           FROM api.network_node nn
           JOIN public.network n ON n.id = nn.network_id
          WHERE nn.last_listed >= now() - max_age
            AND NOT EXISTS (SELECT 1 FROM public.trx t WHERE t.networks @> jsonb_build_object(nn.network_id, nn.node))
       ), free AS (  -- active transmitters, with their modes
         SELECT t.uid, t.site_name, upper(t.callsign::text) AS callsign, t.frequency_tx, t.digital_id, t.echolink_id, t.networks,
                public.trx_technologies(t) AS technologies, nullif(upper(t.dstar_rpt1::text), '') AS dstar_module
           FROM public.trx t
          WHERE t.status::text = 'active'
       ), by_id AS (
         SELECT x.network_id, x.node, x.uid, x.last_listed
           FROM (SELECT nodes.network_id, nodes.node, nodes.last_listed, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   -- EchoLink: the node number is trx.echolink_id (set by hand, so
                   -- no check of the modes); else the DMR id etc. in digital_id.
                   JOIN free f ON CASE WHEN nodes.network_id = 'echolink'
                                       THEN f.echolink_id::text = nodes.node
                                       ELSE f.digital_id::text = nodes.node
                                            AND f.technologies && nodes.technologies END
                              AND NOT f.networks ? nodes.network_id) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), by_module AS (  -- D-STAR node "OE6XDF-B": same callsign, module B = trx.dstar_rpt1
         SELECT x.network_id, x.node, x.uid
           FROM (SELECT nodes.network_id, nodes.node, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.callsign = nodes.callsign
                              AND nodes.node ~ '-[A-Z]$'
                              AND f.dstar_module = right(nodes.node, 1)
                              AND 'dstar' = ANY (f.technologies)
                              AND nodes.technologies = '{dstar}'
                  WHERE NOT f.networks ? nodes.network_id
                    AND NOT EXISTS (SELECT 1 FROM by_id b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), by_freq AS (
         SELECT x.network_id, x.node, x.uid
           FROM (SELECT nodes.network_id, nodes.node, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.callsign = nodes.callsign
                              AND abs(f.frequency_tx::numeric - nodes.frequency) < 0.0005
                              AND f.technologies && nodes.technologies
                  WHERE NOT f.networks ? nodes.network_id
                    AND NOT EXISTS (SELECT 1 FROM by_id b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))
                    AND NOT EXISTS (SELECT 1 FROM by_module b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), taken AS (
         SELECT network_id, node, uid FROM by_id
         UNION ALL
         SELECT network_id, node, uid FROM by_module
         UNION ALL
         SELECT network_id, node, uid FROM by_freq
       ), by_call AS (
         SELECT y.network_id, y.node, y.uid
           FROM (SELECT x.*, row_number() OVER (PARTITION BY x.network_id, x.uid
                                                ORDER BY x.last_listed DESC, x.node) AS pick
                   FROM (SELECT nodes.network_id, nodes.node, nodes.last_listed, f.uid,
                                count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node
                           FROM nodes
                           JOIN free f ON f.callsign = nodes.callsign
                                      AND f.technologies && nodes.technologies
                          WHERE NOT f.networks ? nodes.network_id
                            AND cardinality(nodes.technologies) = 1
                            -- a D-STAR module node never goes to a transmitter of another module
                            AND NOT (nodes.technologies = '{dstar}' AND nodes.node ~ '-[A-Z]$'
                                     AND f.dstar_module IS NOT NULL AND f.dstar_module <> right(nodes.node, 1))
                            AND NOT EXISTS (SELECT 1 FROM taken b
                                             WHERE b.network_id = nodes.network_id
                                               AND (b.node = nodes.node OR b.uid = f.uid))) x
                  WHERE x.trx_per_node = 1) y
          WHERE y.pick = 1
       ), links AS (
         SELECT network_id, node, uid, CASE WHEN network_id = 'echolink' THEN 'echolink_id' ELSE 'digital_id' END AS rule FROM by_id
         UNION ALL
         SELECT network_id, node, uid, 'module' FROM by_module
         UNION ALL
         SELECT network_id, node, uid, 'frequency' FROM by_freq
         UNION ALL
         SELECT network_id, node, uid, 'callsign' FROM by_call
       ), applied AS (
         UPDATE public.trx t
            SET networks = t.networks || a.add
           FROM (SELECT uid, jsonb_object_agg(network_id, node) AS add FROM links GROUP BY uid) a
          WHERE NOT dry_run AND t.uid = a.uid
         RETURNING t.uid
       )
  SELECT l.network_id, l.node, l.uid, f.site_name::text, f.callsign, f.frequency_tx, l.rule
    FROM links l
    JOIN free f ON f.uid = l.uid
   ORDER BY l.network_id, f.site_name, l.node
$$;

COMMENT ON FUNCTION public.trx_networks_autofill(boolean, interval) IS
    'Fills trx.networks from the scraped nodes (rules digital_id / echolink_id, module, frequency, callsign); never changes existing keys. dry_run (default) only lists.';

COMMIT;
