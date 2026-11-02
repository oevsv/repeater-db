-- api.geo(x, y): nearest repeater sites to a point (WGS84 lon/lat), used by the
-- map's "nearby sites" list (GET /api/rpc/geo?x=<lon>&y=<lat>).
--
-- Changes to the previous version:
--  * also returns each site's position (longitude, latitude, WGS84) and its
--    type flags (fm, dmr, ...), so the map can highlight a site from the list
--    without a second request;
--  * distances are true distances in metres on the ellipsoid. Before they were
--    measured in Web Mercator (EPSG:3857), which in Austria inflates them by
--    about 1.5x (e.g. 47 km instead of 32 km); the 200 km search radius is now
--    a real 200 km as well;
--  * only active sites (api.site_type), i.e. the ones shown on the map; before,
--    sites without any active radio were listed too.
-- The first two columns are unchanged, so existing callers keep working.
--
-- Apply:  psql vhf -f 2026-11-01_01_geo_nearby_sites.sql
-- A function's result columns can't be changed with CREATE OR REPLACE, hence
-- DROP + CREATE, in one transaction so the API never misses the function.

BEGIN;

DROP FUNCTION api.geo(double precision, double precision);

CREATE FUNCTION api.geo(x double precision, y double precision)
RETURNS TABLE(
    distance double precision,
    site_name character varying,
    longitude double precision,
    latitude double precision,
    fm boolean,
    dmr boolean,
    c4fm boolean,
    dstar boolean,
    digipeater boolean,
    beacon boolean,
    tetra boolean,
    atv boolean
)
LANGUAGE sql STABLE
AS $_$
    WITH here AS (
        SELECT public.st_setsrid(public.st_makepoint(x, y), 4326)::public.geography AS g
    )
    SELECT round(public.st_distance(here.g, public.st_transform(s.geom, 4326)::public.geography)) AS distance,
           s.site_name, s.longitude, s.latitude,
           s.fm, s.dmr, s.c4fm, s.dstar, s.digipeater, s.beacon, s.tetra, s.atv
      FROM api.site_type s, here
     WHERE public.st_dwithin(here.g, public.st_transform(s.geom, 4326)::public.geography, 200000)
     ORDER BY distance
     LIMIT 10;
$_$;

ALTER FUNCTION api.geo(x double precision, y double precision) OWNER TO dz;
GRANT ALL ON FUNCTION api.geo(x double precision, y double precision) TO web_anon;

COMMIT;

-- PostgREST caches the schema; make it pick up the new result columns.
NOTIFY pgrst, 'reload schema';
