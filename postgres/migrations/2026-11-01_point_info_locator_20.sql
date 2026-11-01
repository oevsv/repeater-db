-- api.point_info(x, y): add locator_20, the Maidenhead locator with 20
-- characters (e.g. JN87JT12EA80AA00AA00), the same precision as the sites'
-- locator_long. The map shows it instead of locator_10.
--
-- locator_10 stays so the web page version deployed before this change keeps
-- working; it can be dropped once the new web page is live.
--
-- Apply after 2026-11-01_point_info.sql:  psql vhf -f 2026-11-01_point_info_locator_20.sql
-- New result column: CREATE OR REPLACE can't do that, hence DROP + CREATE in
-- one transaction.

BEGIN;

DROP FUNCTION api.point_info(double precision, double precision);

CREATE FUNCTION api.point_info(x double precision, y double precision)
RETURNS TABLE(
    longitude double precision,
    latitude double precision,
    longitude_formated character varying,
    latitude_formated character varying,
    locator_6 character varying,
    locator_10 character varying,
    locator_20 character varying
)
LANGUAGE sql STABLE
AS $_$
    SELECT x, y,
           btrim(public.vhf_nice_geo(x))::character varying,
           btrim(public.vhf_nice_geo(y))::character varying,
           public.vhf_maidenhead_loc(x, y, 3),
           public.vhf_maidenhead_loc(x, y, 5),
           public.vhf_maidenhead_loc(x, y, 10);
$_$;

ALTER FUNCTION api.point_info(x double precision, y double precision) OWNER TO dz;
GRANT ALL ON FUNCTION api.point_info(x double precision, y double precision) TO web_anon;

COMMIT;

-- Make PostgREST pick up the new column.
NOTIFY pgrst, 'reload schema';
