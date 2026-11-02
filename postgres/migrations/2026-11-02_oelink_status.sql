-- api.oelink_status: live status of the FM repeaters on OE-Link, from the
-- scraped status page (scripts: scrap_oelink). One row per callsign ever
-- listed there (GET /api/oelink_status):
--
--   callsign     upper case, as in trx.callsign
--   network      'OE-LINK' (label shown on the map)
--   text         repeater ID and hardware of its latest listing, e.g. "932181 RD985S"
--   active       listed within the last 120 minutes
--   last_active  time of the latest scrape that listed it (timestamptz); when
--                not active: when it was last seen
--
-- The status page only lists connected repeaters, so "not listed any more" is
-- what makes a repeater inactive. If the scraper stops, all of them turn
-- inactive after 120 minutes.
--
-- Apply as dz (member of vhf_owner) or postgres:  psql vhf -f 2026-11-02_oelink_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- The view looks up the latest row per callsign; keeps that fast as the raw
-- table grows (one snapshot every few minutes, kept for a year).
CREATE INDEX IF NOT EXISTS scrap_oelink_callsign_ts_idx
    ON public.scrap_oelink (callsign, scraped_timestamp DESC);

CREATE VIEW api.oelink_status AS
    WITH latest AS (
        SELECT DISTINCT ON (callsign) callsign, repeater_id, hardware, scraped_timestamp
          FROM public.scrap_oelink
         WHERE coalesce(callsign, '') <> ''
         ORDER BY callsign, scraped_timestamp DESC
    )
    SELECT callsign,
           'OE-LINK'::text AS network,
           concat_ws(' ', nullif(repeater_id, ''), nullif(hardware, '')) AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.oelink_status IS 'Live status of the FM repeaters on OE-Link (active = listed within 120 minutes)';

GRANT SELECT ON api.oelink_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
