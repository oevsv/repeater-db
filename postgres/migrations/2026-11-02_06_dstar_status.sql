-- D-STAR status from DCS009, XLX905 and ircDDB, added to api.network_status.
-- (scrap_dstar_ref is not used: dstarusers.org is a registry, it says nothing
-- about a repeater being active.)
--
-- All three views have the columns of api.oelink_status: callsign, network,
-- text, active, last_active. One row per callsign ever listed.
--
-- api.dcs009_status   DCS009 (https://xlx232.oevsv.at/_status.html): lists the
--                     connected modules, one line per band. active = listed
--                     within the last 120 minutes; text = the bands of the
--                     latest listing ("70cm, 2m, 23cm").
-- api.xlx905_status   XLX905 (http://xlx905.oevsv.at:8888): lists the connected
--                     stations, callsign with module suffix ("OE9XVI-B").
--                     active = listed within the last 120 minutes; text =
--                     station and band of the latest listing ("OE9XVI-B 70cm").
-- api.ircddb_status   ircDDB (https://status.ircddb.net, Austria): lists ALL
--                     gateways, each "Online" or "Offline". active = the latest
--                     listing says Online and is at most 120 minutes old;
--                     last_active = last time listed as Online. Gateways never
--                     seen Online are left out (no "last active" to show).
--
-- api.network_status: now also D-STAR (technology 'dstar'); same columns as
-- before, so CREATE OR REPLACE keeps its grants.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-02_06_dstar_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE INDEX IF NOT EXISTS scrap_dstar_dcs009_callsign_ts_idx
    ON public.scrap_dstar_dcs009 (callsign, scraped_timestamp DESC);
CREATE INDEX IF NOT EXISTS scrap_dstar_xlx905_callsign_ts_idx
    ON public.scrap_dstar_xlx905 (callsign, scraped_timestamp DESC);
CREATE INDEX IF NOT EXISTS scrap_dstar_ircddb_callsign_ts_idx
    ON public.scrap_dstar_ircddb (callsign, scraped_timestamp DESC);

CREATE VIEW api.dcs009_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS ts
          FROM public.scrap_dstar_dcs009
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'DCS009'::text AS network,
           (SELECT string_agg(DISTINCT replace(d.band, ' Meter', 'm'), ', ')
              FROM public.scrap_dstar_dcs009 d
             WHERE d.callsign = l.callsign AND d.scraped_timestamp = l.ts) AS text,
           (l.ts AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.ts AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

CREATE VIEW api.xlx905_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS ts
          FROM public.scrap_dstar_xlx905
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT l.callsign,
           'XLX905'::text AS network,
           (SELECT string_agg(DISTINCT concat_ws(' ', nullif(x.dv_station, ''), nullif(x.band, '')), ', ')
              FROM public.scrap_dstar_xlx905 x
             WHERE x.callsign = l.callsign AND x.scraped_timestamp = l.ts) AS text,
           (l.ts AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           l.ts AT TIME ZONE 'UTC' AS last_active
      FROM latest l;

CREATE VIEW api.ircddb_status AS
    WITH per_callsign AS (
        SELECT callsign,
               max(scraped_timestamp) AS last_listed,
               max(scraped_timestamp) FILTER (WHERE status = 'Online') AS last_online
          FROM public.scrap_dstar_ircddb
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT callsign,
           'ircDDB'::text AS network,
           ''::text AS text,
           last_online = last_listed
               AND (last_online AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           last_online AT TIME ZONE 'UTC' AS last_active
      FROM per_callsign
     WHERE last_online IS NOT NULL;

COMMENT ON VIEW api.dcs009_status IS 'Live status of the D-STAR repeaters on DCS009 (active = listed within 120 minutes)';
COMMENT ON VIEW api.xlx905_status IS 'Live status of the D-STAR repeaters on XLX905 (active = listed within 120 minutes)';
COMMENT ON VIEW api.ircddb_status IS 'Live status of the D-STAR gateways on ircDDB (active = latest listing Online, within 120 minutes)';

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
    SELECT callsign, network, 'dstar'::text AS technology, text, active, last_active FROM api.ircddb_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link: FM, IPSC2: DMR, YCS232: C4FM, DCS009/XLX905/ircDDB: D-STAR)';

GRANT SELECT ON api.dcs009_status, api.xlx905_status, api.ircddb_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new views.
NOTIFY pgrst, 'reload schema';
