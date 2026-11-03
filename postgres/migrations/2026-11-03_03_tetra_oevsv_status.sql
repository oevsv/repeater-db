-- TETRA status from the SVXReflector "TETRA OE-MASTER", added to
-- api.network_status.
--
-- scrap_tetra_oevsv: snapshots of the reflector's connected gateways with
-- monitored talkgroups (scraper scrap_tetra_oevsv, dashboard
-- http://tetra-reflector.dyndns.org/). Same table as in
-- scripts/create_scrap_tables.sql (IF NOT EXISTS: a fresh setup gets it from
-- there, an existing one from here).
--
-- api.tetra_oevsv_status: like api.svx_oe9_status, one row per callsign ever
-- listed: callsign (without suffix: OE1XCS-T -> OE1XCS), network ('Tetra ÖVSV'),
-- text (empty), active (listed within the last 120 minutes), last_active.
-- The reflector also links FM repeaters (23cm); the map only uses entries whose
-- callsign has a TETRA transmitter at a site.
--
-- api.network_status: plus Tetra ÖVSV (technology tetra); same columns, so
-- CREATE OR REPLACE keeps its grants.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-03_03_tetra_oevsv_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- http://tetra-reflector.dyndns.org/ (table of create_html.php)
CREATE TABLE IF NOT EXISTS public.scrap_tetra_oevsv (
    id SERIAL PRIMARY KEY,
    callsign TEXT,         -- gateway without suffix: OE1XCS
    node TEXT,             -- as listed: OE1XCS-T, OE6XAG-R
    comment TEXT,          -- e.g. "Tetra-Laaerberg/430.3375"
    connected_since TEXT,  -- as shown: "03.11.2026 15:25:45"
    tg TEXT,               -- current talkgroup: "IDLE", "#232"
    monitored_tgs TEXT,    -- blank separated: "9 20 232"
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_tetra_oevsv_callsign_ts_idx ON public.scrap_tetra_oevsv (callsign, scraped_timestamp DESC);

GRANT INSERT ON public.scrap_tetra_oevsv TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_tetra_oevsv_id_seq TO repeater_scrap;

CREATE VIEW api.tetra_oevsv_status AS
    WITH latest AS (
        SELECT callsign, max(scraped_timestamp) AS scraped_timestamp
          FROM public.scrap_tetra_oevsv
         WHERE coalesce(callsign, '') <> ''
         GROUP BY callsign
    )
    SELECT callsign,
           'Tetra ÖVSV'::text AS network,
           ''::text AS text,
           (scraped_timestamp AT TIME ZONE 'UTC') >= now() - interval '120 minutes' AS active,
           scraped_timestamp AT TIME ZONE 'UTC' AS last_active
      FROM latest;

COMMENT ON VIEW api.tetra_oevsv_status IS 'Live status of the TETRA gateways on the reflector TETRA OE-MASTER (active = listed within 120 minutes)';

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
    SELECT callsign, network, 'tetra'::text AS technology, text, active, last_active FROM api.tetra_oevsv_status;

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2: DMR, YCS232: C4FM, DCS009/XLX905/ircDDB: D-STAR, Tetra ÖVSV: TETRA)';

GRANT SELECT ON api.tetra_oevsv_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
