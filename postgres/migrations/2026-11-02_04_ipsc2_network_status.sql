-- DMR status from IPSC2, and one view with the status of all networks.
--
-- api.ipsc2_status: like api.oelink_status, for the DMR repeaters on IPSC2
-- (scraped status page https://ipsc2.oevsv.at/_status.html, scraper
-- scrap_dmr_ipsc2). One row per callsign ever listed there:
--   callsign, network ('IPSC2'), text (repeater ID and hardware),
--   active (listed within the last 120 minutes), last_active (last listed).
-- The DMR hotspot list (scrap_dmr_ipsc2_hotspot) is not used: it contains no
-- repeaters (checked 2026-11-02: none of its 99 entries is a DMR repeater by
-- callsign or DMR ID).
--
-- api.network_status: all networks in one list (GET /api/network_status), as
-- the map uses it; the same columns plus technology ('fm', 'dmr'), so a status
-- only counts for transmitters of that technology. New networks are added here.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-02_04_ipsc2_network_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE INDEX IF NOT EXISTS scrap_dmr_ipsc2_callsign_ts_idx
    ON public.scrap_dmr_ipsc2 (callsign, scraped_timestamp DESC);

CREATE VIEW api.ipsc2_status AS
    WITH latest AS (
        SELECT DISTINCT ON (callsign) callsign, repeater_id, hardware, scraped_timestamp
          FROM public.scrap_dmr_ipsc2
         WHERE coalesce(callsign, '') <> ''
         ORDER BY callsign, scraped_timestamp DESC
    )
    SELECT callsign,
           'IPSC2'::text AS network,
           concat_ws(' ', nullif(repeater_id, ''), nullif(hardware, '')) AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.ipsc2_status IS 'Live status of the DMR repeaters on IPSC2 (active = listed within 120 minutes)';

CREATE VIEW api.network_status AS
    SELECT callsign, network, 'fm'::text AS technology, text, active, last_active FROM api.oelink_status
    UNION ALL
    SELECT callsign, network, 'dmr'::text AS technology, text, active, last_active FROM api.ipsc2_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link: FM, IPSC2: DMR)';

GRANT SELECT ON api.ipsc2_status, api.network_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new views.
NOTIFY pgrst, 'reload schema';
