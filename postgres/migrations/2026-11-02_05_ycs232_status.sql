-- C4FM status from YCS232, added to api.network_status.
--
-- api.ycs232_status: like api.oelink_status / api.ipsc2_status, for the C4FM
-- repeaters on YCS232 (scraped status page https://ycs232.oevsv.at/_status.html,
-- scraper scrap_c4fm_ycs232). One row per callsign ever listed there:
--   callsign (without suffix, see the scraper), network ('YCS232'),
--   text (YCS repeater ID and type, e.g. "2024 DR-2X"),
--   active (listed within the last 120 minutes), last_active (last listed).
-- The list also contains FCS rooms, bridges and systems that are no repeaters;
-- the map only uses entries whose callsign has a C4FM transmitter at a site.
--
-- api.network_status: now FM (OE-Link), DMR (IPSC2) and C4FM (YCS232); same
-- columns as before, so CREATE OR REPLACE keeps its grants.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-02_05_ycs232_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE INDEX IF NOT EXISTS scrap_c4fm_ycs232_callsign_ts_idx
    ON public.scrap_c4fm_ycs232 (callsign, scraped_timestamp DESC);

CREATE VIEW api.ycs232_status AS
    WITH latest AS (
        SELECT DISTINCT ON (callsign) callsign, repeater_id, type, scraped_timestamp
          FROM public.scrap_c4fm_ycs232
         WHERE coalesce(callsign, '') <> ''
         ORDER BY callsign, scraped_timestamp DESC
    )
    SELECT callsign,
           'YCS232'::text AS network,
           concat_ws(' ', nullif(repeater_id, ''), nullif(type, '')) AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.ycs232_status IS 'Live status of the C4FM repeaters on YCS232 (active = listed within 120 minutes)';

CREATE OR REPLACE VIEW api.network_status AS
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.oelink_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.ipsc2_status
    UNION ALL
    SELECT callsign, network, 'c4fm'::text AS technology, text, active, last_active FROM api.ycs232_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link: FM, IPSC2: DMR, YCS232: C4FM)';

GRANT SELECT ON api.ycs232_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
