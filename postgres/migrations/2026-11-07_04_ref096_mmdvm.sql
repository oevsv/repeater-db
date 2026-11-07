-- REF096: also the "Remote Users" of the reflector. Repeaters with MMDVM
-- (e.g. OE7XLH) link to REF096 as users ("HotSpot"), not as gateways, so they
-- were missing and looked inactive. The scraper (scripts/scrapers.py) now
-- stores them too, with link_type 'mmdvm':
--   scrap_dstar_ref096.link_type  'gateway' (table "Linked Gateways") or
--                                 'mmdvm' (table "Remote Users": MMDVM
--                                 repeaters and personal hotspots)
--   reflector_module              gateways: the reflector module linked to;
--                                 users: the module last transmitted on, NULL
--                                 while only listening
-- Status text (api.ref096_status, api.trx_status): gateways "B>A" as before,
-- users "MMDVM", "MMDVM D" (with own module), "MMDVM D>A" (transmitted on A).
-- Personal hotspots appear in api.network_status, but not as unlinked nodes
-- (only callsigns of transmitters are listed there).
--
-- Apply before the new scraper runs (it inserts link_type), as dz or postgres:
--   psql vhf -f 2026-11-07_04_ref096_mmdvm.sql
-- then link the repeaters found now:
--   psql vhf -v apply=1 -f ../scripts/trx_networks_autofill.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

ALTER TABLE public.scrap_dstar_ref096 ADD COLUMN IF NOT EXISTS link_type text DEFAULT 'gateway' NOT NULL;

-- Status text of one REF096 entry.
CREATE FUNCTION public.ref096_text(link_type text, gateway_module text, reflector_module text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT CASE WHEN link_type = 'mmdvm'
                THEN concat_ws(' ', 'MMDVM', nullif(concat_ws('>', nullif(gateway_module, ''), reflector_module), ''))
                ELSE concat_ws('>', nullif(gateway_module, ''), reflector_module)
           END;
$_$;

CREATE OR REPLACE VIEW api.ref096_status AS
    WITH latest AS (  -- per callsign its last listing (all its entries in that snapshot)
        SELECT callsign, max(scraped_timestamp) AS scraped_timestamp
          FROM public.scrap_dstar_ref096
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'REF096'::text AS network,
           (SELECT string_agg(DISTINCT public.ref096_text(r.link_type, r.gateway_module, r.reflector_module), ', ')
              FROM public.scrap_dstar_ref096 r
             WHERE r.callsign = l.callsign AND r.scraped_timestamp = l.scraped_timestamp) AS text,
           (l.scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

COMMENT ON VIEW api.ref096_status IS 'Live status of the D-STAR stations linked to the reflector REF096: gateways and MMDVM users (active = linked within 120 minutes)';

CREATE OR REPLACE VIEW api.trx_status AS
    SELECT tn.trx_uid,
           tn.site_name,
           tn.callsign,
           tn.network_id,
           tn.network,
           tn.node,
           coalesce(nullif(ARRAY(SELECT x FROM unnest(tn.technologies) x WHERE x = ANY (n.technologies)), '{}'),
                    n.technologies) AS technologies,
           CASE tn.network_id
               WHEN 'xlx905' THEN (SELECT x.band FROM public.scrap_dstar_xlx905 x
                                    WHERE x.dv_station = tn.node ORDER BY x.scraped_timestamp DESC LIMIT 1)
               WHEN 'ref096' THEN (SELECT public.ref096_text(r.link_type, r.gateway_module, r.reflector_module)
                                     FROM public.scrap_dstar_ref096 r
                                    WHERE r.node = tn.node ORDER BY r.scraped_timestamp DESC LIMIT 1)
               ELSE ns.text
           END AS text,
           tn.listed_now AS active,
           tn.last_listed AS last_active,
           tn.offline
      FROM api.trx_network tn
      JOIN public.network n ON n.id = tn.network_id
      LEFT JOIN api.network_status ns ON ns.callsign = tn.callsign AND ns.network = tn.network
     WHERE tn.trx_status::text = 'active'
       AND tn.last_listed IS NOT NULL;

COMMIT;
