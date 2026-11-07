-- HamnetDB: whether a site is registered at HamnetDB (https://hamnetdb.net/),
-- shown on the site with a link to https://hamnetdb.net/?m=site&q=<callsign>.
--
-- scrap_hamnet_site: the Austrian HamnetDB sites (callsign "OE" + digit, not
-- deleted), from https://hamnetdb.net/csv.cgi?tab=site&json=1, stored by the
-- scraper scrap_hamnet_site. No history: each run replaces the whole table in
-- one transaction, so a failed run keeps the previous list. Same table as in
-- scripts/create_scrap_tables.sql (IF NOT EXISTS).
-- A site matches a HamnetDB site with the callsign of one of its active
-- transmitters. This is a property of the site only: not a network, nothing
-- in trx.networks. It says the site is registered there, not that it is
-- active (HamnetDB's own flag "inactive" is stored, but not used).
-- api.site_type: new column hamnetdb = the HamnetDB callsign (lower case, as
-- in the HamnetDB URL), NULL if not registered.
-- api.hamnet_site: the stored HamnetDB sites (e.g. for a map layer later).
--
-- Apply before the new scraper runs (it writes the table), as postgres
-- (the scraper may delete from the table):
--   sudo -u postgres psql vhf -f 2026-11-07_08_hamnetdb.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

-- https://hamnetdb.net/csv.cgi?tab=site&json=1, Austrian sites only
CREATE TABLE IF NOT EXISTS public.scrap_hamnet_site (
    id SERIAL PRIMARY KEY,
    callsign TEXT,      -- upper case: OE3XNR
    hamnet_id INTEGER,  -- HamnetDB site id
    name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    elevation INTEGER,  -- antenna height above ground (m)
    ground_asl INTEGER, -- ground above sea level (m)
    inactive BOOLEAN,
    maintainer TEXT,
    edited TEXT,        -- last change at HamnetDB, as listed
    scraped_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS scrap_hamnet_site_callsign_idx ON public.scrap_hamnet_site (callsign);

-- The scraper replaces the contents: DELETE as well.
GRANT INSERT, DELETE ON public.scrap_hamnet_site TO repeater_scrap;
GRANT USAGE ON SEQUENCE public.scrap_hamnet_site_id_seq TO repeater_scrap;

CREATE VIEW api.hamnet_site AS
    SELECT callsign,
           name,
           latitude,
           longitude,
           elevation,
           ground_asl,
           inactive,
           'https://hamnetdb.net/?m=site&q=' || lower(callsign) AS url,
           scraped_timestamp AT TIME ZONE 'UTC' AS scraped
      FROM public.scrap_hamnet_site;

COMMENT ON VIEW api.hamnet_site IS 'Austrian sites registered at HamnetDB (https://hamnetdb.net/), as of the last scraper run';
GRANT SELECT ON api.hamnet_site TO web_anon;

-- As before, plus hamnetdb (at the end: CREATE OR REPLACE VIEW can only add columns there).
CREATE OR REPLACE VIEW api.site_type AS
 SELECT site.site_name,
    site.city,
    bool_or((((trx.status)::text = 'active'::text) AND trx.fm AND ((trx.type_of_station)::text = 'repeater_voice'::text))) AS fm,
    bool_or((((trx.status)::text = 'active'::text) AND trx.dmr AND ((trx.type_of_station)::text = 'repeater_voice'::text))) AS dmr,
    bool_or((((trx.status)::text = 'active'::text) AND trx.c4fm AND ((trx.type_of_station)::text = 'repeater_voice'::text))) AS c4fm,
    bool_or((((trx.status)::text = 'active'::text) AND trx.dstar AND ((trx.type_of_station)::text = 'repeater_voice'::text))) AS dstar,
    bool_or((((trx.status)::text = 'active'::text) AND ((trx.type_of_station)::text = 'digipeater'::text))) AS digipeater,
    bool_or((((trx.status)::text = 'active'::text) AND ((trx.type_of_station)::text = 'beacon'::text))) AS beacon,
    bool_or((((trx.status)::text = 'active'::text) AND trx.tetra AND ((trx.type_of_station)::text = 'repeater_voice'::text))) AS tetra,
    bool_or((((trx.status)::text = 'active'::text) AND ((trx.type_of_station)::text = 'atv'::text))) AS atv,
    array_to_json(array_agg(DISTINCT trx.callsign)) AS callsigns,
    site.longitude,
    site.latitude,
    public.vhf_nice_geo(site.longitude) AS longitude_formated,
    public.vhf_nice_geo(site.latitude) AS latitude_formated,
    site.sea_level,
    site.locator_short,
    site.locator_long,
    site.geo_prefix,
    site.bev_gid,
    site.geom,
    public.st_askml(site.geom) AS st_askml,
    (SELECT lower(min(h.callsign))
       FROM public.scrap_hamnet_site h
      WHERE h.callsign = ANY (array_agg(upper(btrim(trx.callsign))))) AS hamnetdb
   FROM (public.site site
     LEFT JOIN public.trx USING (site_name))
  WHERE ((trx.status)::text = 'active'::text)
  GROUP BY site.site_name, site.city, site.longitude, site.latitude, (public.vhf_nice_geo(site.longitude)), (public.vhf_nice_geo(site.latitude)), site.sea_level, site.locator_short, site.locator_long, site.geo_prefix, site.bev_gid, site.geom;

COMMENT ON COLUMN api.site_type.hamnetdb IS 'Callsign of the site at HamnetDB (lower case; https://hamnetdb.net/?m=site&q=<hamnetdb>), NULL if not registered there';

COMMIT;

NOTIFY pgrst, 'reload schema';
