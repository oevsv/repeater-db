-- D-STAR status from the reflector REF096, added to api.network_status and
-- to the network links; new rule "module" in the automatic fill.
--
-- REF096 (DREFD dashboard http://ref096.dstargateway.org/) shows the gateways
-- linked to the reflector right now - a live view of the reflector's link
-- table ("Status as of <time>", "n remote users - m gateways"), not the
-- registry of dstarusers.org (scrap_dstar_ref, still unused). Each entry is a
-- gateway with its own module, linked to one reflector module: "OE6XDF B" in
-- column A = module B of OE6XDF linked to REF096 A.
--
-- scrap_dstar_ref096: snapshots of the linked gateways (scraper
-- scrap_dstar_ref096); node "OE6XDF-B" as on XLX905. Same table as in
-- scripts/create_scrap_tables.sql (IF NOT EXISTS).
--
-- api.ref096_status: one row per callsign: network 'REF096', text = the
-- gateway's linked modules with the reflector module ("B>A, C>A"), active =
-- linked within the last 120 minutes, last_active = last listed.
--
-- trx_networks_autofill(): new rule 'module' (after 'digital_id'): a D-STAR
-- node "OE6XDF-B" goes to the transmitter of that callsign with
-- trx.dstar_rpt1 = 'B'. The callsign rule no longer links a module node to a
-- transmitter of another module. Applies to REF096 and XLX905.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-04_02_ref096.sql
-- then link:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- http://ref096.dstargateway.org/ (table "Linked Gateways")
CREATE TABLE IF NOT EXISTS public.scrap_dstar_ref096 (
    id SERIAL PRIMARY KEY,
    callsign TEXT,          -- gateway: OE6XDF
    node TEXT,              -- gateway with module: OE6XDF-B
    gateway_module TEXT,    -- B
    reflector_module TEXT,  -- A (REF096 A)
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_dstar_ref096_callsign_ts_idx
    ON public.scrap_dstar_ref096 (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_dstar_ref096 TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_dstar_ref096_id_seq TO repeater_scrap;

CREATE VIEW api.ref096_status AS
    WITH latest AS (  -- per callsign its last listing (all its modules in that snapshot)
        SELECT callsign, max(scraped_timestamp) AS scraped_timestamp
          FROM public.scrap_dstar_ref096
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'REF096'::text AS network,
           (SELECT string_agg(DISTINCT concat_ws('>', nullif(r.gateway_module, ''), r.reflector_module), ', ')
              FROM public.scrap_dstar_ref096 r
             WHERE r.callsign = l.callsign AND r.scraped_timestamp = l.scraped_timestamp) AS text,
           (l.scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

COMMENT ON VIEW api.ref096_status IS 'Live status of the D-STAR gateways linked to the reflector REF096 (active = linked within 120 minutes)';

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
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.ref096_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV: TETRA)';

GRANT SELECT ON api.ref096_status TO web_anon;

-- --- network links ------------------------------------------------------------

INSERT INTO public.network (id, label, url, technologies, sort)
    VALUES ('ref096', 'REF096', 'http://ref096.dstargateway.org/', '{dstar}', 65);

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
                   substring(comment FROM '/(\d+(?:\.\d+)?)\s*$')::numeric AS frequency FROM public.scrap_tetra_oevsv) n
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
         SELECT t.uid, t.site_name, upper(t.callsign::text) AS callsign, t.frequency_tx, t.digital_id, t.networks,
                public.trx_technologies(t) AS technologies, nullif(upper(t.dstar_rpt1::text), '') AS dstar_module
           FROM public.trx t
          WHERE t.status::text = 'active'
       ), by_id AS (
         SELECT x.network_id, x.node, x.uid, x.last_listed
           FROM (SELECT nodes.network_id, nodes.node, nodes.last_listed, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.digital_id::text = nodes.node
                              AND f.technologies && nodes.technologies
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
         SELECT network_id, node, uid, 'digital_id' AS rule FROM by_id
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

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
