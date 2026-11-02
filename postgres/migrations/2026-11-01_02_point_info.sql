-- api.point_info(x, y): locator and formatted coordinates of a point (WGS84
-- lon/lat), used by the map for a clicked / located point
-- (GET /api/rpc/point_info?x=<lon>&y=<lat>, one row).
--
--  * longitude_formated / latitude_formated: same format as for the sites
--    (public.vhf_nice_geo, e.g. 16° 45.600'), without its padding spaces;
--  * locator_6:  Maidenhead locator with 6 characters (e.g. JN87JT);
--  * locator_10: Maidenhead locator with 10 characters (e.g. JN87JT12EA).
--
-- Apply:  psql vhf -f 2026-11-01_02_point_info.sql

BEGIN;

CREATE FUNCTION api.point_info(x double precision, y double precision)
RETURNS TABLE(
    longitude double precision,
    latitude double precision,
    longitude_formated character varying,
    latitude_formated character varying,
    locator_6 character varying,
    locator_10 character varying
)
LANGUAGE sql STABLE
AS $_$
    SELECT x, y,
           btrim(public.vhf_nice_geo(x))::character varying,
           btrim(public.vhf_nice_geo(y))::character varying,
           public.vhf_maidenhead_loc(x, y, 3),
           public.vhf_maidenhead_loc(x, y, 5);
$_$;

ALTER FUNCTION api.point_info(x double precision, y double precision) OWNER TO dz;
GRANT ALL ON FUNCTION api.point_info(x double precision, y double precision) TO web_anon;

COMMIT;

-- Make PostgREST pick up the new function.
NOTIFY pgrst, 'reload schema';
