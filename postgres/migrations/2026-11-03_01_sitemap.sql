-- Sitemap for search engines: GET /api/rpc/sitemap (nginx serves it as
-- /sitemap.xml, see nginx/repeater.oevsv.at). Built from the live data on each
-- request, so new sites and repeater types appear without a deploy.
--
-- Each page is listed in German and English, with the other language as
-- hreflang alternate:
--   /<lang>/all/map, /<lang>/<type>/map   map per repeater type (api.settings)
--   /<lang>/list                          repeater list
--   /<lang>/list/<technology>             network status list (api.network_status)
--   /<lang>/site/<callsign>               one site on the map
--
-- A site is addressed by one of its callsigns. canonical_callsign is the first
-- (alphabetical) callsign of the site's active transmitters that no other site
-- uses, else simply the first one. The website uses the same rule for the
-- canonical link of a site page (frqmap: canonicalCallsign()).
--
-- The function returns the domain "application/xml", which makes PostgREST
-- (media type handlers, v12+) answer with that Content-Type and the raw XML
-- instead of JSON.

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE DOMAIN api."application/xml" AS pg_catalog.xml;

-- Callsign under which a site is linked (NULL: site without active callsign).
CREATE VIEW api.site_canonical AS
 WITH c AS (
         SELECT DISTINCT trx.site_name, upper(trx.callsign::text) AS callsign
           FROM trx
          WHERE trx.status::text = 'active'::text AND COALESCE(trx.callsign, ''::character varying)::text <> ''::text
        ), unique_calls AS (
         SELECT c.callsign
           FROM c
          GROUP BY c.callsign
         HAVING count(*) = 1
        )
 SELECT c.site_name,
    COALESCE(min(c.callsign) FILTER (WHERE c.callsign IN (SELECT unique_calls.callsign FROM unique_calls)), min(c.callsign)) AS canonical_callsign
   FROM c
  GROUP BY c.site_name;

GRANT SELECT ON api.site_canonical TO web_anon;

CREATE FUNCTION api.sitemap() RETURNS api."application/xml"
    LANGUAGE sql STABLE
    AS $$
  WITH base(url) AS (
         VALUES ('https://repeater.oevsv.at'::text)
       ), paths(path) AS (
         SELECT COALESCE(lower(t.value ->> 'type'), 'all') || '/map'
           FROM api.settings s, jsonb_array_elements(s.filter::jsonb -> 'types') t
         UNION
         SELECT 'list'
         UNION
         SELECT 'list/' || n.technology FROM (SELECT DISTINCT technology FROM api.network_status) n
         UNION
         SELECT 'site/' || sc.canonical_callsign
           FROM api.site_canonical sc
           JOIN api.site_type st USING (site_name)
       ), langs(lang) AS (
         VALUES ('de'), ('en')
       )
  SELECT XMLROOT(
           XMLELEMENT(NAME urlset,
             XMLATTRIBUTES('http://www.sitemaps.org/schemas/sitemap/0.9' AS xmlns,
                           'http://www.w3.org/1999/xhtml' AS "xmlns:xhtml"),
             XMLAGG(
               XMLELEMENT(NAME url,
                 XMLELEMENT(NAME loc, b.url || '/' || l.lang || '/' || p.path),
                 XMLELEMENT(NAME "xhtml:link", XMLATTRIBUTES('alternate' AS rel, 'de' AS hreflang,
                                                             b.url || '/de/' || p.path AS href)),
                 XMLELEMENT(NAME "xhtml:link", XMLATTRIBUTES('alternate' AS rel, 'en' AS hreflang,
                                                             b.url || '/en/' || p.path AS href)))
               ORDER BY p.path, l.lang)),
           VERSION '1.0', STANDALONE YES)::api."application/xml"
    FROM base b, paths p, langs l
$$;

COMMENT ON FUNCTION api.sitemap() IS 'Sitemap (sitemaps.org XML) of all pages of the website, served as /sitemap.xml';

GRANT EXECUTE ON FUNCTION api.sitemap() TO web_anon;

COMMIT;

NOTIFY pgrst, 'reload schema';
