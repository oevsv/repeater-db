-- ircDDB offline gateways in the network links.
--
-- ircDDB lists gateways as Online or Offline. api.network_node counted every
-- listing, so a gateway that was never online (historic registrations such as
-- OE4XBJ, OE1XIK) looked alive: listed on /networks, offered for linking. Now,
-- like api.ircddb_status:
--   api.network_node    ircDDB: last_listed = last time listed Online;
--                       gateways never seen Online are left out. New column
--                       offline: the latest listing says Offline.
--   api.trx_network     new column offline; listed_now is false while offline
--   api.network_unlinked new column offline
--   api.networks        listed_now counts nodes that are not offline
-- New columns are appended, so CREATE OR REPLACE keeps the grants and the
-- dependent views and functions.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-04_01_ircddb_offline.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

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

COMMENT ON VIEW api.network_node IS 'Nodes listed by the monitored networks, with the last listing (ircDDB: Online), the reported TX frequency and whether it is offline now';

CREATE OR REPLACE VIEW api.trx_network AS
    SELECT t.uid AS trx_uid,
           l.key AS network_id,
           n.label AS network,
           n.url AS network_url,
           l.value AS node,
           t.site_name,
           upper(t.callsign::text) AS callsign,
           t.frequency_tx,
           t.type_of_station,
           t.status AS trx_status,
           public.trx_technologies(t) AS technologies,
           nn.frequency AS node_frequency,
           nn.last_listed,
           coalesce(nn.last_listed >= now() - interval '120 minutes' AND NOT nn.offline, false) AS listed_now,
           coalesce(nn.offline, false) AS offline
      FROM public.trx t
     CROSS JOIN LATERAL jsonb_each_text(t.networks) l
      JOIN public.network n ON n.id = l.key
      LEFT JOIN api.network_node nn ON nn.network_id = l.key AND nn.node = l.value
     WHERE l.value IS NOT NULL;

CREATE OR REPLACE VIEW api.networks AS
    SELECT n.id, n.label, n.url, n.technologies, n.sort,
           (SELECT count(*) FROM api.trx_network tn WHERE tn.network_id = n.id) AS linked,
           (SELECT count(*) FROM api.network_node nn
             WHERE nn.network_id = n.id AND nn.last_listed >= now() - interval '120 minutes'
               AND NOT nn.offline) AS listed_now
      FROM public.network n;

CREATE OR REPLACE VIEW api.network_unlinked AS
    SELECT nn.network_id, n.label AS network, n.url AS network_url, nn.node, nn.callsign,
           nn.frequency AS node_frequency, nn.last_listed, c.candidates, nn.offline
      FROM api.network_node nn
      JOIN public.network n ON n.id = nn.network_id
     CROSS JOIN LATERAL (
            SELECT jsonb_agg(jsonb_build_object(
                       'trx_uid', t.uid, 'site_name', t.site_name, 'frequency_tx', t.frequency_tx,
                       'technologies', public.trx_technologies(t),
                       'fits', public.trx_technologies(t) && n.technologies,
                       'excluded', t.networks ? n.id AND t.networks -> n.id = 'null'::jsonb,
                       'linked_node', t.networks ->> n.id)
                       ORDER BY t.site_name, t.frequency_tx) AS candidates
              FROM public.trx t
             WHERE t.status::text = 'active' AND upper(t.callsign::text) = nn.callsign) c
     WHERE nn.last_listed >= now() - interval '30 days'
       AND c.candidates IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.trx t WHERE t.networks @> jsonb_build_object(nn.network_id, nn.node));

COMMIT;

-- Make PostgREST pick up the new columns.
NOTIFY pgrst, 'reload schema';
