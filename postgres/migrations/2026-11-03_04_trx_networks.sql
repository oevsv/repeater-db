-- Links between transmitters (trx) and the nodes of the monitored networks.
--
-- Until now a network status was attached by callsign + technology. That
-- breaks for mixed networks (SVXLink OE9 and Tetra ÖVSV link FM and TETRA) and
-- for callsigns with several transmitters of one mode (OE3XNR: FM 145.6375 and
-- 438.875, only the latter is on OE-LINK). Now each transmitter names its
-- nodes explicitly:
--
--   trx.networks  jsonb object {network id: node}, e.g.
--                 {"oelink": "932832"}                       OE3XNR 438.875
--                 {"ipsc2": "232305"}                        OE3XNR DMR
--                 {"tetra_oevsv": "OE1XCS-T"}                OE1XCS TETRA
--                 {"svx_oe9": "OE9XVV-R", "oelink": "..."}   several networks
--                 {"svx_oe9": null}   explicitly NOT in this network: the
--                                     automatic fill leaves it alone
--   node          the identifier the network lists (see network_node below):
--                 OE-LINK, IPSC2: repeater ID; SVXLink OE9, Tetra ÖVSV: node
--                 with suffix; YCS232: station; XLX905: station with module
--                 (OE9XGV-B); DCS009, ircDDB: callsign
--
-- Objects:
--   network                    the networks (id, label, dashboard URL, technologies)
--   trx.networks               the links; a trigger checks network ids and that a
--                              node is linked to one transmitter only
--   trx_technologies(trx)      the transmitter's modes as text[] ({fm}, {dmr,fm}, ...)
--   api.network_node           every node a network listed, with last_listed and
--                              the frequency it reports (SVXLink tx.freq, Tetra comment)
--   api.trx_network            one row per link, with network, transmitter and
--                              last_listed of the node
--   api.networks               the networks with counts, for the website
--   api.network_unlinked       nodes listed recently, not linked, whose callsign
--                              is in trx - with the candidate transmitters
--   trx_networks_autofill()    fills trx.networks automatically (dry run by
--                              default), see postgres/scripts/trx_networks_autofill.sql
--   api.sitemap()              plus the page /networks
--
-- The status views (api.*_status, api.network_status) are unchanged here; they
-- move to these links in a separate step.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-03_04_trx_networks.sql
-- then fill the links:
--   psql vhf -f ../scripts/trx_networks_autofill.sql              (dry run)
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql   (apply)

BEGIN;
SET LOCAL ROLE vhf_owner;

-- --- networks ---------------------------------------------------------------

CREATE TABLE public.network (
    id text PRIMARY KEY CHECK (id ~ '^[a-z0-9_]+$'),
    label text NOT NULL,          -- as shown on the website
    url text,                     -- dashboard of the network
    technologies text[] NOT NULL  -- modes of the transmitters it can link
        CHECK (technologies <@ ARRAY['fm', 'dmr', 'c4fm', 'dstar', 'tetra'] AND technologies <> '{}'),
    sort smallint NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.network IS 'Networks / repeater systems whose nodes are scraped; trx.networks links transmitters to their nodes';

INSERT INTO public.network (id, label, url, technologies, sort) VALUES
    ('oelink',      'OE-LINK',     'https://oe-link.oevsv.at/_status.html',                         '{fm}',       10),
    ('svx_oe9',     'SVXLink OE9', 'https://svx.oe9hamnet.at/',                                     '{fm,tetra}', 20),
    ('ipsc2',       'IPSC2',       'https://ipsc2.oevsv.at/_status.html',                           '{dmr}',      30),
    ('ycs232',      'YCS232',      'https://ycs232.oevsv.at/_status.html',                          '{c4fm}',     40),
    ('dcs009',      'DCS009',      'https://xlx232.oevsv.at/_status.html',                          '{dstar}',    50),
    ('xlx905',      'XLX905',      'http://xlx905.oevsv.at:8888/index.php?show=repeaters',          '{dstar}',    60),
    ('ircddb',      'ircDDB',      'https://status.ircddb.net/cgi-bin/ircddb-gw?AUT',               '{dstar}',    70),
    ('tetra_oevsv', 'Tetra ÖVSV',  'http://tetra-reflector.dyndns.org/',                            '{tetra,fm}', 80);

GRANT SELECT ON public.network TO web_anon;

-- --- links in trx -----------------------------------------------------------

ALTER TABLE public.trx
    ADD COLUMN networks jsonb NOT NULL DEFAULT '{}'::jsonb
        CONSTRAINT trx_networks_object CHECK (jsonb_typeof(networks) = 'object');

COMMENT ON COLUMN public.trx.networks IS
    'Nodes of this transmitter in the monitored networks: {network id: node}; null = explicitly not in that network (automatic fill skips it)';

-- Finds the transmitter of a node: networks @> '{"oelink": "932832"}'
CREATE INDEX trx_networks_idx ON public.trx USING gin (networks jsonb_path_ops);

CREATE FUNCTION public.trx_networks_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    k text;
    v jsonb;
    other bigint;
BEGIN
    FOR k, v IN SELECT key, value FROM jsonb_each(NEW.networks) LOOP
        IF NOT EXISTS (SELECT 1 FROM public.network WHERE id = k) THEN
            RAISE EXCEPTION 'trx %: unknown network "%" in networks (known: table network)', NEW.uid, k;
        END IF;
        CONTINUE WHEN jsonb_typeof(v) = 'null';
        IF jsonb_typeof(v) <> 'string' OR btrim(v #>> '{}') = '' THEN
            RAISE EXCEPTION 'trx %: networks.% must be the node as text, or null - not %', NEW.uid, k, v;
        END IF;
        SELECT t.uid INTO other FROM public.trx t
         WHERE t.uid <> NEW.uid AND t.networks @> jsonb_build_object(k, v) LIMIT 1;
        IF FOUND THEN
            RAISE EXCEPTION 'trx %: node % of network % is already linked to trx %', NEW.uid, v, k, other;
        END IF;
    END LOOP;
    RETURN NEW;
END
$$;

COMMENT ON FUNCTION public.trx_networks_check() IS 'trx.networks: known networks only, node as text or null, each node linked to one transmitter';

CREATE TRIGGER trx_networks_check BEFORE INSERT OR UPDATE OF networks ON public.trx
    FOR EACH ROW EXECUTE FUNCTION public.trx_networks_check();

-- The transmitter's modes: {fm}, {dmr}, {dmr,fm}, ... (order as on the website).
CREATE FUNCTION public.trx_technologies(t public.trx) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_remove(ARRAY[CASE WHEN t.fm THEN 'fm' END, CASE WHEN t.dmr THEN 'dmr' END,
                            CASE WHEN t.c4fm THEN 'c4fm' END, CASE WHEN t.dstar THEN 'dstar' END,
                            CASE WHEN t.tetra THEN 'tetra' END], NULL)
$$;

-- --- views --------------------------------------------------------------------

-- Every node a network listed, with the callsign (without suffix) and when it
-- was listed last. ircDDB lists offline gateways too.
-- frequency: TX frequency (MHz) the node reported in its latest listing, if
-- any - SVXLink OE9 tx.freq, Tetra ÖVSV the end of the comment
-- ("Tetra-Hegerberg/430.4125"). Often a default (SVXLink "431.0").
CREATE VIEW api.network_node AS
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
            SELECT 'tetra_oevsv' AS network_id, node, callsign, scraped_timestamp,
                   substring(comment FROM '/(\d+(?:\.\d+)?)\s*$')::numeric AS frequency FROM public.scrap_tetra_oevsv) n
     WHERE coalesce(node, '') <> ''
     GROUP BY network_id, node, callsign;

COMMENT ON VIEW api.network_node IS 'Nodes listed by the monitored networks, with the last listing and the reported TX frequency';

-- One row per link (trx.networks entries that are not null).
CREATE VIEW api.trx_network AS
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
           coalesce(nn.last_listed >= now() - interval '120 minutes', false) AS listed_now
      FROM public.trx t
     CROSS JOIN LATERAL jsonb_each_text(t.networks) l
      JOIN public.network n ON n.id = l.key
      LEFT JOIN api.network_node nn ON nn.network_id = l.key AND nn.node = l.value
     WHERE l.value IS NOT NULL;

COMMENT ON VIEW api.trx_network IS 'Transmitter <-> network node links (trx.networks), with the node''s last listing';

-- The networks with counts, for the page /networks.
CREATE VIEW api.networks AS
    SELECT n.id, n.label, n.url, n.technologies, n.sort,
           (SELECT count(*) FROM api.trx_network tn WHERE tn.network_id = n.id) AS linked,
           (SELECT count(*) FROM api.network_node nn
             WHERE nn.network_id = n.id AND nn.last_listed >= now() - interval '120 minutes') AS listed_now
      FROM public.network n;

COMMENT ON VIEW api.networks IS 'Monitored networks with the number of linked transmitters and of nodes listed now';

-- Work list for manual linking: nodes listed in the last 30 days that are not
-- linked, whose callsign belongs to an active transmitter. candidates: all
-- active transmitters of that callsign; "fits" = mode carried by the network,
-- "excluded" = the transmitter is marked as not in this network (null).
-- Nodes of unknown callsigns (hotspots, missing transmitters) are not listed.
CREATE VIEW api.network_unlinked AS
    SELECT nn.network_id, n.label AS network, n.url AS network_url, nn.node, nn.callsign,
           nn.frequency AS node_frequency, nn.last_listed, c.candidates
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

COMMENT ON VIEW api.network_unlinked IS 'Nodes listed within 30 days, not linked to a transmitter, whose callsign is in trx (with candidates)';

GRANT SELECT ON api.network_node, api.trx_network, api.networks, api.network_unlinked TO web_anon;

-- --- automatic fill -------------------------------------------------------------

-- Links nodes listed within max_age to transmitters, without touching existing
-- entries (a network key that is present - also with null - is never changed):
--   rule 'digital_id'  node = trx.digital_id (OE-LINK, IPSC2 repeater IDs) and
--                      the transmitter has a mode the network carries
--   rule 'frequency'   same callsign, and the frequency the node reports equals
--                      trx.frequency_tx (SVXLink OE9, Tetra ÖVSV)
--   rule 'callsign'    only for networks of one mode: the node's callsign has
--                      exactly one active transmitter of that mode. Mixed
--                      networks (FM + TETRA) need the ID or the frequency -
--                      otherwise e.g. a TETRA node of a site whose TETRA
--                      transmitter is missing in trx would end up on its FM one.
-- A node or transmitter with several matches is left for manual linking
-- (api.network_unlinked). Several nodes on one transmitter (OE9XDW-R,
-- OE9XDW-SR): the one listed last wins. Returns the links (made, or with
-- dry_run only proposed).
CREATE FUNCTION public.trx_networks_autofill(dry_run boolean DEFAULT true, max_age interval DEFAULT '30 days')
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
                public.trx_technologies(t) AS technologies
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
                                       AND (b.node = nodes.node OR b.uid = f.uid))) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), taken AS (
         SELECT network_id, node, uid FROM by_id
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
                            AND NOT EXISTS (SELECT 1 FROM taken b
                                             WHERE b.network_id = nodes.network_id
                                               AND (b.node = nodes.node OR b.uid = f.uid))) x
                  WHERE x.trx_per_node = 1) y
          WHERE y.pick = 1
       ), links AS (
         SELECT network_id, node, uid, 'digital_id' AS rule FROM by_id
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
    'Fills trx.networks from the scraped nodes (rules digital_id, callsign); never changes existing keys. dry_run (default) only lists.';

REVOKE ALL ON FUNCTION public.trx_networks_autofill(boolean, interval) FROM PUBLIC;

-- --- sitemap: plus /networks ------------------------------------------------------

CREATE OR REPLACE FUNCTION api.sitemap() RETURNS api."application/xml"
    LANGUAGE sql STABLE
    AS $$
  WITH base(url) AS (
         VALUES ('https://repeater.oevsv.at'::text)
       ), paths(path) AS (
         SELECT COALESCE(lower(t.value ->> 'type'), 'all') || '/map'
           FROM api.settings s, jsonb_array_elements(s.filter::jsonb -> 'types') t
         UNION
         SELECT 'list'
         UNION
         SELECT 'networks'
         UNION
         SELECT 'list/' || n.technology FROM (SELECT DISTINCT technology FROM api.network_status) n
         UNION
         SELECT 'site/' || sc.canonical_callsign
           FROM api.site_canonical sc
           JOIN api.site_type st USING (site_name)
       ), langs(lang) AS (
         VALUES ('de'), ('en')
       )
  SELECT XMLROOT(
           XMLELEMENT(NAME urlset,
             XMLATTRIBUTES('http://www.sitemaps.org/schemas/sitemap/0.9' AS xmlns,
                           'http://www.w3.org/1999/xhtml' AS "xmlns:xhtml"),
             XMLAGG(
               XMLELEMENT(NAME url,
                 XMLELEMENT(NAME loc, b.url || '/' || l.lang || '/' || p.path),
                 XMLELEMENT(NAME "xhtml:link", XMLATTRIBUTES('alternate' AS rel, 'de' AS hreflang,
                                                             b.url || '/de/' || p.path AS href)),
                 XMLELEMENT(NAME "xhtml:link", XMLATTRIBUTES('alternate' AS rel, 'en' AS hreflang,
                                                             b.url || '/en/' || p.path AS href)))
               ORDER BY p.path, l.lang)),
           VERSION '1.0', STANDALONE YES)::api."application/xml"
    FROM base b, paths p, langs l
$$;

COMMIT;

-- Make PostgREST pick up the new views.
NOTIFY pgrst, 'reload schema';
