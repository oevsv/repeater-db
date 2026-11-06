--
-- PostgreSQL database dump
--

\restrict edmOrUe6xU0VAeByadN4NSPzLNGzzTGGIjlDCgDB8Gs6Khdktct05dVgAxYngE5

-- Dumped from database version 15.19 (Debian 15.19-1.pgdg13+2)
-- Dumped by pg_dump version 15.19 (Debian 15.19-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA api;


ALTER SCHEMA api OWNER TO postgres;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_raster; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;


--
-- Name: EXTENSION postgis_raster; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_raster IS 'PostGIS raster types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: application/xml; Type: DOMAIN; Schema: api; Owner: vhf_owner
--

CREATE DOMAIN api."application/xml" AS xml;


ALTER DOMAIN api."application/xml" OWNER TO vhf_owner;

--
-- Name: geo(double precision, double precision); Type: FUNCTION; Schema: api; Owner: vhf_owner
--

CREATE FUNCTION api.geo(x double precision, y double precision) RETURNS TABLE(distance double precision, site_name character varying, longitude double precision, latitude double precision, fm boolean, dmr boolean, c4fm boolean, dstar boolean, digipeater boolean, beacon boolean, tetra boolean, atv boolean)
    LANGUAGE sql STABLE
    AS $$
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
$$;


ALTER FUNCTION api.geo(x double precision, y double precision) OWNER TO vhf_owner;

--
-- Name: point_info(double precision, double precision); Type: FUNCTION; Schema: api; Owner: vhf_owner
--

CREATE FUNCTION api.point_info(x double precision, y double precision) RETURNS TABLE(longitude double precision, latitude double precision, longitude_formated character varying, latitude_formated character varying, locator_6 character varying, locator_10 character varying, locator_20 character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT x, y,
           btrim(public.vhf_nice_geo(x))::character varying,
           btrim(public.vhf_nice_geo(y))::character varying,
           public.vhf_maidenhead_loc(x, y, 3),
           public.vhf_maidenhead_loc(x, y, 5),
           public.vhf_maidenhead_loc(x, y, 10);
$$;


ALTER FUNCTION api.point_info(x double precision, y double precision) OWNER TO vhf_owner;

--
-- Name: sitemap(); Type: FUNCTION; Schema: api; Owner: vhf_owner
--

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
         SELECT 'networks'
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


ALTER FUNCTION api.sitemap() OWNER TO vhf_owner;

--
-- Name: FUNCTION sitemap(); Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON FUNCTION api.sitemap() IS 'Sitemap (sitemaps.org XML) of all pages of the website, served as /sitemap.xml';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ticket_create(text, text, text); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_create(heading text, body text, site_name text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    me public.users := public.ticket_current_user();
    new_id uuid;
BEGIN
    IF length(btrim(heading)) > 200 THEN
        RAISE EXCEPTION 'heading too long (max. 200 characters)' USING ERRCODE = '22001';
    END IF;
    INSERT INTO public.ticket (user_id, heading, site_name)
    VALUES (me.id, btrim(heading), nullif(btrim(site_name), ''))
    RETURNING ticket.id INTO new_id;
    INSERT INTO public.ticket_message (ticket_id, user_id, staff, body)
    VALUES (new_id, me.id, me.staff4, body);
    RETURN new_id;
END;
$$;


ALTER FUNCTION api.ticket_create(heading text, body text, site_name text) OWNER TO vhf_ticket_writer;

--
-- Name: ticket_get(uuid); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_get(id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    me public.users := public.ticket_current_user();
    t public.ticket := public.ticket_visible(ticket_get.id, me);
BEGIN
    RETURN json_build_object(
        'id', t.id, 'heading', t.heading, 'status', t.status, 'site_name', t.site_name,
        'created', t.created, 'updated', t.updated,
        'author_callsign', (SELECT u.callsign FROM public.users u WHERE u.id = t.user_id),
        'own', t.user_id = me.id,
        'messages', coalesce((
            SELECT json_agg(json_build_object(
                       'id', m.id, 'body', m.body, 'created', m.created, 'staff', m.staff,
                       'callsign', u.callsign, 'own', m.user_id = me.id) ORDER BY m.created)
              FROM public.ticket_message m
              JOIN public.users u ON u.id = m.user_id
             WHERE m.ticket_id = t.id), '[]'::json));
END;
$$;


ALTER FUNCTION api.ticket_get(id uuid) OWNER TO vhf_ticket_writer;

--
-- Name: ticket_list(); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_list() RETURNS TABLE(id uuid, heading character varying, status text, site_name character varying, created timestamp with time zone, updated timestamp with time zone, author_callsign character varying, own boolean, messages bigint, last_from_staff boolean)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
    WITH me AS (SELECT * FROM public.ticket_current_user())
    SELECT t.id, t.heading, t.status, t.site_name, t.created, t.updated,
           u.callsign, t.user_id = me.id,
           (SELECT count(*) FROM public.ticket_message m WHERE m.ticket_id = t.id),
           (SELECT m.staff FROM public.ticket_message m WHERE m.ticket_id = t.id
             ORDER BY m.created DESC LIMIT 1)
      FROM me, public.ticket t
      JOIN public.users u ON u.id = t.user_id
     WHERE t.user_id = me.id OR me.staff4
     ORDER BY t.updated DESC;
$$;


ALTER FUNCTION api.ticket_list() OWNER TO vhf_ticket_writer;

--
-- Name: ticket_reply(uuid, text); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_reply(id uuid, body text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    me public.users := public.ticket_current_user();
    t public.ticket := public.ticket_visible(ticket_reply.id, me);
BEGIN
    INSERT INTO public.ticket_message (ticket_id, user_id, staff, body)
    VALUES (t.id, me.id, me.staff4, body);
    -- Staff answering someone else's ticket: answered; otherwise waiting for staff.
    UPDATE public.ticket
       SET status = CASE WHEN me.staff4 AND t.user_id <> me.id THEN 'answered' ELSE 'open' END,
           updated = now()
     WHERE ticket.id = t.id;
END;
$$;


ALTER FUNCTION api.ticket_reply(id uuid, body text) OWNER TO vhf_ticket_writer;

--
-- Name: ticket_set_status(uuid, text); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_set_status(id uuid, status text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    me public.users := public.ticket_current_user();
    t public.ticket := public.ticket_visible(ticket_set_status.id, me);
BEGIN
    IF NOT me.staff4 AND ticket_set_status.status NOT IN ('open', 'closed') THEN
        RAISE EXCEPTION 'only staff may set status %', ticket_set_status.status USING ERRCODE = '42501';
    END IF;
    UPDATE public.ticket
       SET status = ticket_set_status.status, updated = now()
     WHERE ticket.id = t.id;
END;
$$;


ALTER FUNCTION api.ticket_set_status(id uuid, status text) OWNER TO vhf_ticket_writer;

--
-- Name: ticket_staff_only(); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_staff_only() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT coalesce((SELECT c.staff_only FROM public.ticket_config c), true);
$$;


ALTER FUNCTION api.ticket_staff_only() OWNER TO vhf_ticket_writer;

--
-- Name: ticket_whoami(); Type: FUNCTION; Schema: api; Owner: vhf_ticket_writer
--

CREATE FUNCTION api.ticket_whoami() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    me public.users;
BEGIN
    BEGIN
        me := public.ticket_current_user();
    EXCEPTION WHEN SQLSTATE 'PT404' THEN
        RETURN json_build_object('staff', false, 'enabled', false, 'attention', 0);
    END;
    RETURN json_build_object(
        'staff', me.staff4,
        'enabled', true,
        'attention', (SELECT count(*) FROM public.ticket t
                       WHERE (t.user_id = me.id AND t.status = 'answered')
                          OR (me.staff4 AND t.status = 'open')));
END;
$$;


ALTER FUNCTION api.ticket_whoami() OWNER TO vhf_ticket_writer;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    callsign character varying(20),
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    staff4 boolean DEFAULT false NOT NULL,
    email character varying(254)
);


ALTER TABLE public.users OWNER TO vhf_owner;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.users IS 'Users who logged in via OpenID Connect; written by api.user_login()';


--
-- Name: COLUMN users.id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.users.id IS 'OpenID subject (sub) from Keycloak';


--
-- Name: COLUMN users.callsign; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.users.callsign IS 'Callsign from the latest login (preferred_username, upper case); may be NULL';


--
-- Name: COLUMN users.staff4; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.users.staff4 IS 'Staff: sees and answers all tickets (set by hand)';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.users.email IS 'E-mail from the login (SSO), for ticket notifications; stored by ticket_current_user()';


--
-- Name: user_login(); Type: FUNCTION; Schema: api; Owner: vhf_login_writer
--

CREATE FUNCTION api.user_login() RETURNS public.users
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    claims json := nullif(current_setting('request.jwt.claims', true), '')::json;
    user_id uuid := (claims ->> 'sub')::uuid;
    user_callsign character varying := nullif(upper(btrim(claims ->> 'callsign')), '');
    result public.users;
BEGIN
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'no user in token (claim sub missing)'
            USING ERRCODE = '42501'; -- insufficient_privilege: PostgREST answers 401/403
    END IF;

    INSERT INTO public.users AS u (id, callsign, first_seen, last_seen)
    VALUES (user_id, user_callsign, now(), now())
    ON CONFLICT (id) DO UPDATE
        SET callsign = EXCLUDED.callsign,
            last_seen = now()
    RETURNING u.* INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION api.user_login() OWNER TO vhf_login_writer;

--
-- Name: ticket_current_user(); Type: FUNCTION; Schema: public; Owner: vhf_ticket_writer
--

CREATE FUNCTION public.ticket_current_user() RETURNS public.users
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    claims json := nullif(current_setting('request.jwt.claims', true), '')::json;
    user_id uuid := (claims ->> 'sub')::uuid;
    new_email character varying := left(nullif(btrim(claims ->> 'email'), ''), 254);
    result public.users;
BEGIN
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'not logged in (claim sub missing)' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO result FROM public.users u WHERE u.id = user_id;
    IF NOT FOUND THEN
        INSERT INTO public.users (id, callsign, email)
        VALUES (user_id, nullif(upper(btrim(claims ->> 'callsign')), ''), new_email)
        ON CONFLICT (id) DO NOTHING;
        SELECT * INTO result FROM public.users u WHERE u.id = user_id;
    ELSIF new_email IS NOT NULL AND new_email IS DISTINCT FROM result.email THEN
        UPDATE public.users u SET email = new_email WHERE u.id = user_id
        RETURNING * INTO result;
    END IF;
    IF NOT result.staff4 AND coalesce((SELECT c.staff_only FROM public.ticket_config c), true) THEN
        RAISE EXCEPTION 'tickets are restricted to staff' USING ERRCODE = 'PT404';
    END IF;
    RETURN result;
END;
$$;


ALTER FUNCTION public.ticket_current_user() OWNER TO vhf_ticket_writer;

--
-- Name: ticket_message_mail(); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.ticket_message_mail() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    PERFORM pg_notify('ticket_mail', NEW.id::text);
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.ticket_message_mail() OWNER TO vhf_owner;

--
-- Name: ticket; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.ticket (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    heading character varying(200) NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    site_name character varying(100),
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ticket_heading_check CHECK ((btrim((heading)::text) <> ''::text)),
    CONSTRAINT ticket_status_check CHECK ((status = ANY (ARRAY['open'::text, 'answered'::text, 'closed'::text])))
);


ALTER TABLE public.ticket OWNER TO vhf_owner;

--
-- Name: TABLE ticket; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.ticket IS 'Updates submitted by logged-in users (website /ticket); written by the api.ticket_* functions';


--
-- Name: COLUMN ticket.id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket.id IS 'Ticket id, in the URL /ticket/<id>';


--
-- Name: COLUMN ticket.status; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket.status IS 'open: waiting for staff, answered: waiting for the user, closed: done';


--
-- Name: COLUMN ticket.site_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket.site_name IS 'Site the update is about (optional, as given; no foreign key: site names are not unique)';


--
-- Name: COLUMN ticket.updated; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket.updated IS 'Last message or status change';


--
-- Name: ticket_visible(uuid, public.users); Type: FUNCTION; Schema: public; Owner: vhf_ticket_writer
--

CREATE FUNCTION public.ticket_visible(ticket_id uuid, me public.users) RETURNS public.ticket
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    result public.ticket;
BEGIN
    SELECT * INTO result FROM public.ticket t
     WHERE t.id = ticket_id AND (t.user_id = me.id OR me.staff4);
    IF NOT FOUND THEN
        RAISE EXCEPTION 'ticket not found' USING ERRCODE = 'PT404';
    END IF;
    RETURN result;
END;
$$;


ALTER FUNCTION public.ticket_visible(ticket_id uuid, me public.users) OWNER TO vhf_ticket_writer;

--
-- Name: trx_networks_autofill(boolean, interval); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.trx_networks_autofill(dry_run boolean DEFAULT true, max_age interval DEFAULT '30 days'::interval) RETURNS TABLE(network_id text, node text, trx_uid bigint, site_name text, callsign text, frequency_tx double precision, rule text)
    LANGUAGE sql
    AS $_$
  WITH nodes AS (
         SELECT nn.network_id, nn.node, nn.callsign, nn.last_listed, nn.frequency, n.technologies
           FROM api.network_node nn
           JOIN public.network n ON n.id = nn.network_id
          WHERE nn.last_listed >= now() - max_age
            AND NOT EXISTS (SELECT 1 FROM public.trx t WHERE t.networks @> jsonb_build_object(nn.network_id, nn.node))
       ), free AS (  -- active transmitters, with their modes
         SELECT t.uid, t.site_name, upper(t.callsign::text) AS callsign, t.frequency_tx, t.digital_id, t.networks,
                public.trx_technologies(t) AS technologies, nullif(upper(t.dstar_rpt1::text), '') AS dstar_module
           FROM public.trx t
          WHERE t.status::text = 'active'
       ), by_id AS (
         SELECT x.network_id, x.node, x.uid, x.last_listed
           FROM (SELECT nodes.network_id, nodes.node, nodes.last_listed, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.digital_id::text = nodes.node
                              AND f.technologies && nodes.technologies
                              AND NOT f.networks ? nodes.network_id) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), by_module AS (  -- D-STAR node "OE6XDF-B": same callsign, module B = trx.dstar_rpt1
         SELECT x.network_id, x.node, x.uid
           FROM (SELECT nodes.network_id, nodes.node, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.callsign = nodes.callsign
                              AND nodes.node ~ '-[A-Z]$'
                              AND f.dstar_module = right(nodes.node, 1)
                              AND 'dstar' = ANY (f.technologies)
                              AND nodes.technologies = '{dstar}'
                  WHERE NOT f.networks ? nodes.network_id
                    AND NOT EXISTS (SELECT 1 FROM by_id b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), by_freq AS (
         SELECT x.network_id, x.node, x.uid
           FROM (SELECT nodes.network_id, nodes.node, f.uid,
                        count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node,
                        count(*) OVER (PARTITION BY nodes.network_id, f.uid) AS nodes_per_trx
                   FROM nodes
                   JOIN free f ON f.callsign = nodes.callsign
                              AND abs(f.frequency_tx::numeric - nodes.frequency) < 0.0005
                              AND f.technologies && nodes.technologies
                  WHERE NOT f.networks ? nodes.network_id
                    AND NOT EXISTS (SELECT 1 FROM by_id b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))
                    AND NOT EXISTS (SELECT 1 FROM by_module b
                                     WHERE b.network_id = nodes.network_id
                                       AND (b.node = nodes.node OR b.uid = f.uid))) x
          WHERE x.trx_per_node = 1 AND x.nodes_per_trx = 1
       ), taken AS (
         SELECT network_id, node, uid FROM by_id
         UNION ALL
         SELECT network_id, node, uid FROM by_module
         UNION ALL
         SELECT network_id, node, uid FROM by_freq
       ), by_call AS (
         SELECT y.network_id, y.node, y.uid
           FROM (SELECT x.*, row_number() OVER (PARTITION BY x.network_id, x.uid
                                                ORDER BY x.last_listed DESC, x.node) AS pick
                   FROM (SELECT nodes.network_id, nodes.node, nodes.last_listed, f.uid,
                                count(*) OVER (PARTITION BY nodes.network_id, nodes.node) AS trx_per_node
                           FROM nodes
                           JOIN free f ON f.callsign = nodes.callsign
                                      AND f.technologies && nodes.technologies
                          WHERE NOT f.networks ? nodes.network_id
                            AND cardinality(nodes.technologies) = 1
                            -- a D-STAR module node never goes to a transmitter of another module
                            AND NOT (nodes.technologies = '{dstar}' AND nodes.node ~ '-[A-Z]$'
                                     AND f.dstar_module IS NOT NULL AND f.dstar_module <> right(nodes.node, 1))
                            AND NOT EXISTS (SELECT 1 FROM taken b
                                             WHERE b.network_id = nodes.network_id
                                               AND (b.node = nodes.node OR b.uid = f.uid))) x
                  WHERE x.trx_per_node = 1) y
          WHERE y.pick = 1
       ), links AS (
         SELECT network_id, node, uid, 'digital_id' AS rule FROM by_id
         UNION ALL
         SELECT network_id, node, uid, 'module' FROM by_module
         UNION ALL
         SELECT network_id, node, uid, 'frequency' FROM by_freq
         UNION ALL
         SELECT network_id, node, uid, 'callsign' FROM by_call
       ), applied AS (
         UPDATE public.trx t
            SET networks = t.networks || a.add
           FROM (SELECT uid, jsonb_object_agg(network_id, node) AS add FROM links GROUP BY uid) a
          WHERE NOT dry_run AND t.uid = a.uid
         RETURNING t.uid
       )
  SELECT l.network_id, l.node, l.uid, f.site_name::text, f.callsign, f.frequency_tx, l.rule
    FROM links l
    JOIN free f ON f.uid = l.uid
   ORDER BY l.network_id, f.site_name, l.node
$_$;


ALTER FUNCTION public.trx_networks_autofill(dry_run boolean, max_age interval) OWNER TO vhf_owner;

--
-- Name: FUNCTION trx_networks_autofill(dry_run boolean, max_age interval); Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON FUNCTION public.trx_networks_autofill(dry_run boolean, max_age interval) IS 'Fills trx.networks from the scraped nodes (rules digital_id, callsign); never changes existing keys. dry_run (default) only lists.';


--
-- Name: trx_networks_check(); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.trx_networks_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    k text;
    v jsonb;
    other bigint;
BEGIN
    FOR k, v IN SELECT key, value FROM jsonb_each(NEW.networks) LOOP
        IF NOT EXISTS (SELECT 1 FROM public.network WHERE id = k) THEN
            RAISE EXCEPTION 'trx %: unknown network "%" in networks (known: table network)', NEW.uid, k;
        END IF;
        CONTINUE WHEN jsonb_typeof(v) = 'null';
        IF jsonb_typeof(v) <> 'string' OR btrim(v #>> '{}') = '' THEN
            RAISE EXCEPTION 'trx %: networks.% must be the node as text, or null - not %', NEW.uid, k, v;
        END IF;
        SELECT t.uid INTO other FROM public.trx t
         WHERE t.uid <> NEW.uid AND t.networks @> jsonb_build_object(k, v) LIMIT 1;
        IF FOUND THEN
            RAISE EXCEPTION 'trx %: node % of network % is already linked to trx %', NEW.uid, v, k, other;
        END IF;
    END LOOP;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.trx_networks_check() OWNER TO vhf_owner;

--
-- Name: FUNCTION trx_networks_check(); Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON FUNCTION public.trx_networks_check() IS 'trx.networks: known networks only, node as text or null, each node linked to one transmitter';


--
-- Name: trx; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.trx (
    uid bigint NOT NULL,
    type_of_station character varying(50) DEFAULT 'repeater_voice'::character varying NOT NULL,
    frequency_tx double precision,
    frequency_rx double precision,
    callsign character varying(10),
    antenna_heigth double precision,
    site_name character varying(100) NOT NULL,
    sysop character varying(10),
    url character varying(500),
    hardware character varying(100),
    mmdvm boolean,
    solar_power boolean,
    battery_power boolean,
    status character varying,
    fm boolean,
    fm_wakeup character varying(50),
    ctcss_tx double precision,
    ctcss_rx double precision,
    echolink boolean,
    echolink_id bigint,
    digital_id bigint,
    dmr boolean,
    ipsc2 boolean,
    brandmeister boolean,
    network_registered boolean,
    c4fm boolean,
    c4fm_groups character varying(30),
    dstar boolean,
    dstar_rpt1 character varying(1),
    dstar_rpt2 character varying(1),
    tetra boolean,
    other_mode boolean,
    other_mode_name character varying(50),
    comment character varying(1000),
    internal character varying(3000),
    created_at timestamp with time zone DEFAULT now(),
    cc integer,
    networks jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT trx_networks_object CHECK ((jsonb_typeof(networks) = 'object'::text))
);


ALTER TABLE public.trx OWNER TO vhf_owner;

--
-- Name: TABLE trx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.trx IS 'All OE repeater, including packet radio and beacons (and other stuff using spectrum in the relevant bands, eg. transponders)';


--
-- Name: COLUMN trx.frequency_tx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.frequency_tx IS 'in MHz';


--
-- Name: COLUMN trx.frequency_rx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.frequency_rx IS 'in MHz';


--
-- Name: COLUMN trx.callsign; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN trx.antenna_heigth; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN trx.site_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.site_name IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN trx.sysop; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN trx.url; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN trx.hardware; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.hardware IS 'Hardware of station';


--
-- Name: COLUMN trx.mmdvm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN trx.solar_power; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN trx.battery_power; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN trx.status; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN trx.fm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.fm IS 'Analogue FM station';


--
-- Name: COLUMN trx.fm_wakeup; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.fm_wakeup IS 'Tone or DTMF needed for activation of repeater, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN trx.ctcss_tx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN trx.ctcss_rx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN trx.echolink; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN trx.echolink_id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN trx.digital_id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN trx.dmr; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN trx.ipsc2; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN trx.brandmeister; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN trx.network_registered; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN trx.c4fm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN trx.c4fm_groups; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN trx.dstar; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN trx.dstar_rpt1; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN trx.dstar_rpt2; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN trx.tetra; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.tetra IS 'True if Tetra station';


--
-- Name: COLUMN trx.other_mode; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN trx.other_mode_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN trx.comment; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.comment IS 'Public visible comment';


--
-- Name: COLUMN trx.internal; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN trx.created_at; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN trx.cc; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.cc IS 'Color Code (default DMR code is 1)';


--
-- Name: COLUMN trx.networks; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.trx.networks IS 'Nodes of this transmitter in the monitored networks: {network id: node}; null = explicitly not in that network (automatic fill skips it)';


--
-- Name: trx_technologies(public.trx); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.trx_technologies(t public.trx) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_remove(ARRAY[CASE WHEN t.fm THEN 'fm' END, CASE WHEN t.dmr THEN 'dmr' END,
                            CASE WHEN t.c4fm THEN 'c4fm' END, CASE WHEN t.dstar THEN 'dstar' END,
                            CASE WHEN t.tetra THEN 'tetra' END], NULL)
$$;


ALTER FUNCTION public.trx_technologies(t public.trx) OWNER TO vhf_owner;

--
-- Name: vhf_band_common(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_band_common(frequency double precision) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
   declare
      common boolean;

	BEGIN
select common_band into common from bands where 
    frequency >= frequency_from and
    frequency <= frequency_to
    limit 1;
		
    return common;
	END;
$$;


ALTER FUNCTION public.vhf_band_common(frequency double precision) OWNER TO vhf_owner;

--
-- Name: vhf_band_name(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_band_name(frequency double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;

	BEGIN
select band_name into name from bands where 
    frequency >= frequency_from and
    frequency <= frequency_to
    limit 1;
		
    return name;
	END;
$$;


ALTER FUNCTION public.vhf_band_name(frequency double precision) OWNER TO vhf_owner;

--
-- Name: vhf_channel_name(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_channel_name(frequency_tx double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      
   BEGIN
     -- default, use common (aka old) format - e.g. R1x
     RETURN  channel_name (frequency_tx,NULL,0);
   END
$$;


ALTER FUNCTION public.vhf_channel_name(frequency_tx double precision) OWNER TO vhf_owner;

--
-- Name: vhf_channel_name(double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_channel_name(frequency_tx double precision, frequency_rx double precision, format integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;

band6m_lower constant double precision := 50;

band6m_upper constant double precision := 54;     
     
band2m_lower constant double precision := 144;

band2m_upper constant double precision := 146;

band70cm_lower constant double precision := 430;

band70cm_upper constant double precision := 440;

band6m_offset constant double  precision := 0.6;

band2m_offset constant double  precision := 0.6;

band70cm_offset constant double  precision := 7.6; 

nonstandard_offset boolean := false;


chan2m_old varchar[] := '{"R00", "R00x", "R0", "R0x","R1","R1x","R2","R2x","R3","R3x",
							 "R4", "R4x","R5","R5x","R6","R6x","R7","R7x"}';
-- index for channel calculations
      idx integer;
      
      
   begin
	 -- check offset 
	 -- 6m band  
     if (frequency_tx >= band6m_lower and
         frequency_tx <= band6m_upper and 
       abs(frequency_tx - frequency_rx - band6m_offset) > 0.001) then  
          nonstandard_offset = true;
     end if;   
	 -- 2m band  
     if (frequency_tx >= band2m_lower and
         frequency_tx <= band2m_upper and 
       abs(frequency_tx - frequency_rx - band2m_offset) > 0.001) then  
          nonstandard_offset = true;
     end if;      
     -- 70cm band  
     if (frequency_tx >= band70cm_lower and
         frequency_tx <= band70cm_upper and 
       abs(frequency_tx - frequency_rx - band70cm_offset) > 0.001) then  
          nonstandard_offset = true;
     end if; 
     -- old format (R1, R70)
     if (format = 0) then
     
      -- 2m range R00 - R7x
      if (frequency_tx >= 145.575 and
          frequency_tx <= 145.7875) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          name = chan2m_old[round((frequency_tx-145.575)/0.0125)+1];
      end if;
      -- 70cm range R30-R123 (broad range, goes beyond real repepater channels)
      if (frequency_tx >= 437.650 and
          frequency_tx <= 439.975) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          -- idx is zero at 437.650 and progresses with 1/12,5kHz (would be R30)
          idx = round((frequency_tx-437.650)/0.0125);
          -- even number - thus no "x" added
          if (mod(idx,2)=0) then
            name = concat('R',(idx/2+30)::varchar);
          else 
            name = concat('R',(idx/2+30)::varchar,'x');
          end if;
       
      end if;
     else
     -- new format RV48, RU680
        -- 6m
        if (frequency_tx >= 51 and
          frequency_tx <= 54) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.01) - round(frequency_tx/0.01) < 0.001 then
          idx = round((frequency_tx-51)*100);
          name = concat('RF',(idx)::varchar);
        end if;
        -- 2m
        if (frequency_tx >= 145.2 and
          frequency_tx <= 145.7875) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          idx = round((frequency_tx-145)*80);
          name = concat('RV',(idx)::varchar);
        end if;
        -- 70cm
        if (frequency_tx >= 437.650 and
          frequency_tx <= 439.975) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          idx = round((frequency_tx-430)*80);
          name = concat('RU',(idx)::varchar);
        end if;
     end if;
      
     if (name is not null and nonstandard_offset) then
       name = concat (name,'!');
     end if;
     RETURN name;
   END
$$;


ALTER FUNCTION public.vhf_channel_name(frequency_tx double precision, frequency_rx double precision, format integer) OWNER TO vhf_owner;

--
-- Name: vhf_chirp_Tone(double precision, double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public."vhf_chirp_Tone"(ctcss_tx double precision, ctcss_rx double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;

     BEGIN
if (ctcss_tx is null and ctcss_rx is null) then
-- 'None' is encoded as empty string
   return '';
elseif  (ctcss_tx is null and ctcss_rx is not null) then
   return 'Tone';
elseif  (ctcss_tx is not null and ctcss_rx is null) then
   return 'TSQL';
elseif (ctcss_tx = ctcss_rx) then
   return 'TSQL';
else
   return 'Cross';
end if;  
	END;
$$;


ALTER FUNCTION public."vhf_chirp_Tone"(ctcss_tx double precision, ctcss_rx double precision) OWNER TO vhf_owner;

--
-- Name: vhf_chirp_ctonefreq(double precision, double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_chirp_ctonefreq(ctcss_tx double precision, ctcss_rx double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
   declare
      default_ctcss constant float8 := 162.2; 

     BEGIN
if (ctcss_tx is null and ctcss_rx is null) then
   return default_ctcss;
elseif (ctcss_tx is null and ctcss_rx is not null) then
   return ctcss_rx;
else 
   return ctcss_tx;
end if;  
	END;
$$;


ALTER FUNCTION public.vhf_chirp_ctonefreq(ctcss_tx double precision, ctcss_rx double precision) OWNER TO vhf_owner;

--
-- Name: vhf_chirp_rtonefreq(double precision, double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_chirp_rtonefreq(ctcss_tx double precision, ctcss_rx double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
   declare
      default_ctcss constant float8 := 162.2;

     BEGIN
if (ctcss_rx is not null) then 
  return ctcss_rx;
elsif (ctcss_tx is not null) then 
  return  ctcss_tx;
else 
  return default_ctcss;
end if;

	END;
$$;


ALTER FUNCTION public.vhf_chirp_rtonefreq(ctcss_tx double precision, ctcss_rx double precision) OWNER TO vhf_owner;

--
-- Name: vhf_maidenhead_loc(double precision, double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_maidenhead_loc(longitude double precision, latitude double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      
   BEGIN
     -- short default locator (3 pairs aka 6 digits
     RETURN  vhf_maidenhead_loc (longitude,latitude,3);
   END
$$;


ALTER FUNCTION public.vhf_maidenhead_loc(longitude double precision, latitude double precision) OWNER TO vhf_owner;

--
-- Name: vhf_maidenhead_loc(double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_maidenhead_loc(longitude double precision, latitude double precision, pairs integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   DECLARE
      loc varchar;                --  123456789012345678
                                  --  123456789012345678901234
      alphabet_c constant varchar := 'ABCDEFGHIJKLMNOPQRSTUVWX';
      alphabet_n constant varchar := '0123456789';

      long_offset constant float8 := 180;
      long_range constant float8 := 360;
      long_rem float8;
     
      lat_offset constant float8 := 90;
      lat_range constant float8 := 180;
      lat_rem float8;

      digit_n int;
      base int;
      c varchar;
      -- minimum number of pairs (e.g. JN68UB)      
      pairs_min constant int := 3;
      -- maximum pair number
      pairs_max constant int := 10;
      counter int;
      
   BEGIN
      --  Lat 48.07823  Long 13.730722 Locator: JN68UB78QS  => J6I7Q und N8B8S

	  -- longitude: -180..+180, east is positive 
	  -- latitude: -90..+90, north is positive
	   
      -- range check parameters
	  -- raise notice 'Longitude: "%" ', longitude;
	  -- raise notice 'Latitude: "%" ', latitude; 
      if (latitude > 90 or latitude < -90 or
          longitude > 180 or longitude < -180 or
          pairs < pairs_min or pairs > pairs_max) then 
        return NULL;        
      end if;

      loc = '';
      long_rem = (longitude + long_offset)/long_range;
      lat_rem = (latitude + lat_offset)/lat_range;
      -- raise notice 'Long rem: "%" ', long_rem;
	  -- raise notice 'Lat rem: "%" ', lat_rem;
      -- long 180 and -180 are the same place, thus should have the same locator
      if long_rem = 1 then
        long_rem = 0;
      end if;  
      
      for counter in 1..pairs loop
         -- raise notice 'counter: %', counter;
                         
         -- determine base 
         if (counter = 1) then
            -- first pair is A-R
            -- 18 zones of longitude of 20° each
            -- 18 zones of latitude 10° each
            base = 18;
         else
           if (mod(counter,2)=1) then
             -- odd pair is A-X 
             base = 24;
           else
             -- even pair is 0-9
             base = 10;             
           end if;    
         end if;   
         -- raise notice 'base: %', base;
        
         -- longitude first in pair
          -- longitude is singlar at poles, IARU R1 defines to use the first character
          if (latitude = 90 or latitude = -90) then
            digit_n=0;
          else
            digit_n = trunc(long_rem*base);
            if (digit_n > base-1) then
              digit_n = base-1;
            end if;
            long_rem = (long_rem*base - digit_n);
          end if; 
          if (mod(counter,2)=1) then
            c = substr(alphabet_c,digit_n+1,1);
          else
            c = substr(alphabet_n,digit_n+1,1);
          end if;
          loc = concat (loc,c);
          -- raise notice 'Longitude: "%" % % ', c,digit_n,long_rem;
          -- latitude second in pair
          digit_n = trunc(lat_rem*base);
          if (digit_n > base-1) then
            digit_n = base-1;
          end if;
          lat_rem = (lat_rem*base - digit_n);
          if (mod(counter,2)=1) then
            c = substr(alphabet_c,digit_n+1,1);
          else
            c = substr(alphabet_n,digit_n+1,1);
          end if;
          loc = concat (loc,c);
          -- raise notice 'Latitude: "%" % % ', c, digit_n,lat_rem;
      end loop;            
     RETURN loc;
   END
$$;


ALTER FUNCTION public.vhf_maidenhead_loc(longitude double precision, latitude double precision, pairs integer) OWNER TO vhf_owner;

--
-- Name: vhf_nice_display(character varying); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_nice_display(org character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
        
    begin
	  org = replace(org,'Ä','Ae');
	  org = replace(org,'ä','ae');
	  org = replace(org,'Ö','Oe');
	  org = replace(org,'ö','oe');
	  org = replace(org,'Ü','ue');
	  org = replace(org,'ü','ue');
	  org = replace(org,'ß','ss');
      return org;
	END;
$$;


ALTER FUNCTION public.vhf_nice_display(org character varying) OWNER TO vhf_owner;

--
-- Name: vhf_nice_frq(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_nice_frq(frequency double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      idx bigint;
          
    begin
       -- idx progresses with 1/0,5kHz steps
       idx = round((frequency)/0.0001);
       -- even number - thus no extra digit added
       if (mod(idx,10)=0) then
         name = trim(to_char(frequency,'999 999 990.999'));
       else 
         -- use narrow space unicode (u2009) for final digit 
         name = trim(to_char(frequency,concat('999 999 999.999',E'\u2009','9')));
       end if;

       return name;
	END;
$$;


ALTER FUNCTION public.vhf_nice_frq(frequency double precision) OWNER TO vhf_owner;

--
-- Name: vhf_nice_geo(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_nice_geo(geo double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      deg bigint;
      minutes float8;
          
    begin
	   deg = trunc(geo);
	   minutes = (geo-deg)*60;
	   name = concat(
	       to_char(deg,'900'),
	       '°',
	       to_char(minutes, '90.999'),
	       E'\'');
       return name;
	END;
$$;


ALTER FUNCTION public.vhf_nice_geo(geo double precision) OWNER TO vhf_owner;

--
-- Name: vhf_nice_geo_dms(double precision); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_nice_geo_dms(geo double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      deg bigint;
      minutes float8;
      seconds float8;
          
    begin
	    -- 47°06'15"N
	   deg = trunc(geo);
	   minutes = (geo-deg)*60;
	   seconds = (minutes-trunc(minutes))*60;
	   name = concat(
	       to_char(deg,'900'),
	       '°',
	       to_char(trunc(minutes), '90'),
	       E'\'',
	       to_char(round(seconds), '90'),
	       E'\"');
       return name;
	END;
$$;


ALTER FUNCTION public.vhf_nice_geo_dms(geo double precision) OWNER TO vhf_owner;

--
-- Name: vhf_trigger_import_hamnet_site(); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_trigger_import_hamnet_site() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
           if (NEW.latitude is null or new.longitude is null)
           then
              NEW.geom = null;
           end if;

       if (NEW.latitude is not null and NEW.longitude is not null)
       then
           -- set geometry geom
           new.geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326),3857);

           -- set see level
           SELECT INTO NEW.sea_level ST_Value(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)))
           FROM dhm WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)));   
           NEW.see_level = round(NEW.see_level);
           
           -- set geo prefix according to region
           SELECT map.prefix,bev.gid
                INTO NEW.geo_prefix, new.bev_gid
                FROM oesterreich_bev_vgd_lam as bev
                LEFT JOIN bl_kz_prefix map on map.bl_kz=bev.bl_kz, import_hamnet_site as r
                WHERE ST_intersects(ST_Transform(NEW.geom, 31287), bev.geom)
                LIMIT 1;
           -- set locator
           NEW.locator_short = maidenhead_loc(NEW.longitude,new.latitude);     
           NEW.locator_long = maidenhead_loc(NEW.longitude,new.latitude,10);     
           
       end if;
        
       return new;

    END;
$$;


ALTER FUNCTION public.vhf_trigger_import_hamnet_site() OWNER TO vhf_owner;

--
-- Name: vhf_trigger_site(); Type: FUNCTION; Schema: public; Owner: vhf_owner
--

CREATE FUNCTION public.vhf_trigger_site() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
           if (NEW.latitude is null or new.longitude is null)
           then
              NEW.geom = null;
           end if;

       if (NEW.latitude is not null and NEW.longitude is not null)
       then
           -- set geometry geom
           new.geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326),3857);

           -- set sea level
           SELECT INTO NEW.sea_level ST_Value(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)))
           FROM dhm WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)));   
           NEW.sea_level = round(NEW.sea_level);
           
           -- set geo prefix according to region
           SELECT map.prefix,bev.gid
                INTO NEW.geo_prefix, new.bev_gid
                FROM oesterreich_bev_vgd_lam as bev
                LEFT JOIN bl_kz_prefix map on map.bl_kz=bev.bl_kz, site as r
                WHERE ST_intersects(ST_Transform(NEW.geom, 31287), bev.geom)
                LIMIT 1;
           -- set locator
           NEW.locator_short = vhf_maidenhead_loc(NEW.longitude,new.latitude);     
           NEW.locator_long = vhf_maidenhead_loc(NEW.longitude,new.latitude,10);     
           
       end if;
        
       return new;

    END;
$$;


ALTER FUNCTION public.vhf_trigger_site() OWNER TO vhf_owner;

--
-- Name: scrap_dmr_brandmeister; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dmr_brandmeister (
    id integer NOT NULL,
    callsign text,
    device_id text,
    device_callsign text,
    status text,
    last_seen timestamp without time zone,
    tx text,
    rx text,
    colorcode text,
    hardware text,
    firmware text,
    city text,
    lat text,
    lng text,
    master text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dmr_brandmeister OWNER TO vhf_owner;

--
-- Name: brandmeister_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.brandmeister_status AS
 WITH device AS (
         SELECT DISTINCT ON (scrap_dmr_brandmeister.device_id) scrap_dmr_brandmeister.callsign,
            scrap_dmr_brandmeister.device_id,
            scrap_dmr_brandmeister.hardware,
            scrap_dmr_brandmeister.last_seen
           FROM public.scrap_dmr_brandmeister
          WHERE ((COALESCE(scrap_dmr_brandmeister.callsign, ''::text) <> ''::text) AND (scrap_dmr_brandmeister.last_seen IS NOT NULL))
          ORDER BY scrap_dmr_brandmeister.device_id, scrap_dmr_brandmeister.scraped_timestamp DESC
        ), latest AS (
         SELECT DISTINCT ON (device.callsign) device.callsign,
            device.device_id,
            device.hardware,
            device.last_seen
           FROM device
          ORDER BY device.callsign, device.last_seen DESC
        )
 SELECT latest.callsign,
    'Brandmeister'::text AS network,
    concat_ws(' '::text, NULLIF(latest.device_id, ''::text), NULLIF(latest.hardware, ''::text)) AS text,
    ((latest.last_seen AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.last_seen AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.brandmeister_status OWNER TO vhf_owner;

--
-- Name: VIEW brandmeister_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.brandmeister_status IS 'Live status of the Austrian DMR devices on Brandmeister (active = seen by Brandmeister within 120 minutes)';


--
-- Name: scrap_dstar_dcs009; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dstar_dcs009 (
    id integer NOT NULL,
    nr text,
    callsign text,
    band text,
    linked text,
    dcs_group text,
    via text,
    software text,
    hb_timer text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dstar_dcs009 OWNER TO vhf_owner;

--
-- Name: dcs009_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.dcs009_status AS
 WITH latest AS (
         SELECT scrap_dstar_dcs009.callsign,
            max(scrap_dstar_dcs009.scraped_timestamp) AS ts
           FROM public.scrap_dstar_dcs009
          WHERE (COALESCE(scrap_dstar_dcs009.callsign, ''::text) <> ''::text)
          GROUP BY scrap_dstar_dcs009.callsign
        )
 SELECT l.callsign,
    'DCS009'::text AS network,
    ( SELECT string_agg(DISTINCT replace(d.band, ' Meter'::text, 'm'::text), ', '::text) AS string_agg
           FROM public.scrap_dstar_dcs009 d
          WHERE ((d.callsign = l.callsign) AND (d.scraped_timestamp = l.ts))) AS text,
    ((l.ts AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (l.ts AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest l;


ALTER TABLE api.dcs009_status OWNER TO vhf_owner;

--
-- Name: VIEW dcs009_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.dcs009_status IS 'Live status of the D-STAR repeaters on DCS009 (active = listed within 120 minutes)';


--
-- Name: scrap_dmr_ipsc2; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dmr_ipsc2 (
    id integer NOT NULL,
    nr text,
    callsign text,
    info text,
    repeater_id text,
    ts1 text,
    cq text,
    ts1_info text,
    ts2 text,
    ts2_info text,
    ref text,
    start text,
    hardware text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dmr_ipsc2 OWNER TO vhf_owner;

--
-- Name: ipsc2_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.ipsc2_status AS
 WITH latest AS (
         SELECT DISTINCT ON (scrap_dmr_ipsc2.callsign) scrap_dmr_ipsc2.callsign,
            scrap_dmr_ipsc2.repeater_id,
            scrap_dmr_ipsc2.hardware,
            scrap_dmr_ipsc2.scraped_timestamp
           FROM public.scrap_dmr_ipsc2
          WHERE (COALESCE(scrap_dmr_ipsc2.callsign, ''::text) <> ''::text)
          ORDER BY scrap_dmr_ipsc2.callsign, scrap_dmr_ipsc2.scraped_timestamp DESC
        )
 SELECT latest.callsign,
    'IPSC2'::text AS network,
    concat_ws(' '::text, NULLIF(latest.repeater_id, ''::text), NULLIF(latest.hardware, ''::text)) AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.ipsc2_status OWNER TO vhf_owner;

--
-- Name: VIEW ipsc2_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.ipsc2_status IS 'Live status of the DMR repeaters on IPSC2 (active = listed within 120 minutes)';


--
-- Name: scrap_dstar_ircddb; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dstar_ircddb (
    id integer NOT NULL,
    callsign text,
    status text,
    country text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dstar_ircddb OWNER TO vhf_owner;

--
-- Name: ircddb_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.ircddb_status AS
 WITH per_callsign AS (
         SELECT scrap_dstar_ircddb.callsign,
            max(scrap_dstar_ircddb.scraped_timestamp) AS last_listed,
            max(scrap_dstar_ircddb.scraped_timestamp) FILTER (WHERE (scrap_dstar_ircddb.status = 'Online'::text)) AS last_online
           FROM public.scrap_dstar_ircddb
          WHERE (COALESCE(scrap_dstar_ircddb.callsign, ''::text) <> ''::text)
          GROUP BY scrap_dstar_ircddb.callsign
        )
 SELECT per_callsign.callsign,
    'ircDDB'::text AS network,
    ''::text AS text,
    ((per_callsign.last_online = per_callsign.last_listed) AND ((per_callsign.last_online AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval))) AS active,
    (per_callsign.last_online AT TIME ZONE 'UTC'::text) AS last_active
   FROM per_callsign
  WHERE (per_callsign.last_online IS NOT NULL);


ALTER TABLE api.ircddb_status OWNER TO vhf_owner;

--
-- Name: VIEW ircddb_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.ircddb_status IS 'Live status of the D-STAR gateways on ircDDB (active = latest listing Online, within 120 minutes)';


--
-- Name: scrap_c4fm_ycs232; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_c4fm_ycs232 (
    id integer NOT NULL,
    nr text,
    callsign text,
    station text,
    group_code text,
    name text,
    qrg text,
    repeater_id text,
    dg_id text,
    name2 text,
    rx_tx text,
    mode text,
    type text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_c4fm_ycs232 OWNER TO vhf_owner;

--
-- Name: scrap_dstar_ref096; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dstar_ref096 (
    id integer NOT NULL,
    callsign text,
    node text,
    gateway_module text,
    reflector_module text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dstar_ref096 OWNER TO vhf_owner;

--
-- Name: scrap_dstar_xlx905; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dstar_xlx905 (
    id integer NOT NULL,
    no text,
    flag text,
    callsign text,
    dv_station text,
    band text,
    last_heard text,
    linked_for text,
    protocol text,
    module text,
    ip_address text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dstar_xlx905 OWNER TO vhf_owner;

--
-- Name: scrap_fm_svx_oe9; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_fm_svx_oe9 (
    id integer NOT NULL,
    callsign text,
    node text,
    monitored_tgs text,
    node_location text,
    sysop text,
    tx_freq text,
    tx_name text,
    tx_pwr text,
    lat text,
    long text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_fm_svx_oe9 OWNER TO vhf_owner;

--
-- Name: scrap_oelink; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_oelink (
    id integer NOT NULL,
    nr text,
    callsign text,
    info text,
    repeater_id text,
    ts1 text,
    cq text,
    ts1_info text,
    ts2 text,
    ts2_info text,
    ref text,
    start text,
    hardware text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_oelink OWNER TO vhf_owner;

--
-- Name: scrap_tetra_de; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_tetra_de (
    id integer NOT NULL,
    callsign text,
    node text,
    monitored_tgs text,
    source_tag text,
    node_location text,
    tx_freq text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_tetra_de OWNER TO vhf_owner;

--
-- Name: scrap_tetra_oevsv; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_tetra_oevsv (
    id integer NOT NULL,
    callsign text,
    node text,
    comment text,
    connected_since text,
    tg text,
    monitored_tgs text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_tetra_oevsv OWNER TO vhf_owner;

--
-- Name: network_node; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.network_node AS
 SELECT n.network_id,
    n.node,
    n.callsign,
    (max(n.scraped_timestamp) AT TIME ZONE 'UTC'::text) AS last_listed,
    (array_agg(n.frequency ORDER BY n.scraped_timestamp DESC))[1] AS frequency,
        CASE
            WHEN (n.network_id = 'ircddb'::text) THEN COALESCE((( SELECT s.status
               FROM public.scrap_dstar_ircddb s
              WHERE (s.callsign = n.node)
              ORDER BY s.scraped_timestamp DESC
             LIMIT 1) = 'Offline'::text), false)
            ELSE false
        END AS offline
   FROM ( SELECT 'oelink'::text AS network_id,
            scrap_oelink.repeater_id AS node,
            scrap_oelink.callsign,
            scrap_oelink.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_oelink
        UNION ALL
         SELECT 'svx_oe9'::text AS network_id,
            scrap_fm_svx_oe9.node,
            scrap_fm_svx_oe9.callsign,
            scrap_fm_svx_oe9.scraped_timestamp,
                CASE
                    WHEN (scrap_fm_svx_oe9.tx_freq ~ '^\d+(\.\d+)?$'::text) THEN (scrap_fm_svx_oe9.tx_freq)::numeric
                    ELSE NULL::numeric
                END AS frequency
           FROM public.scrap_fm_svx_oe9
        UNION ALL
         SELECT 'ipsc2'::text AS network_id,
            scrap_dmr_ipsc2.repeater_id AS node,
            scrap_dmr_ipsc2.callsign,
            scrap_dmr_ipsc2.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_dmr_ipsc2
        UNION ALL
         SELECT 'ycs232'::text AS network_id,
            scrap_c4fm_ycs232.station AS node,
            scrap_c4fm_ycs232.callsign,
            scrap_c4fm_ycs232.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_c4fm_ycs232
        UNION ALL
         SELECT 'dcs009'::text AS network_id,
            scrap_dstar_dcs009.callsign AS node,
            scrap_dstar_dcs009.callsign,
            scrap_dstar_dcs009.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_dstar_dcs009
        UNION ALL
         SELECT 'xlx905'::text AS network_id,
            scrap_dstar_xlx905.dv_station AS node,
            scrap_dstar_xlx905.callsign,
            scrap_dstar_xlx905.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_dstar_xlx905
        UNION ALL
         SELECT 'ircddb'::text AS network_id,
            scrap_dstar_ircddb.callsign AS node,
            scrap_dstar_ircddb.callsign,
            scrap_dstar_ircddb.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_dstar_ircddb
          WHERE (scrap_dstar_ircddb.status = 'Online'::text)
        UNION ALL
         SELECT 'ref096'::text AS network_id,
            scrap_dstar_ref096.node,
            scrap_dstar_ref096.callsign,
            scrap_dstar_ref096.scraped_timestamp,
            NULL::numeric AS frequency
           FROM public.scrap_dstar_ref096
        UNION ALL
         SELECT 'brandmeister'::text AS network_id,
            scrap_dmr_brandmeister.device_id AS node,
            scrap_dmr_brandmeister.callsign,
            scrap_dmr_brandmeister.last_seen AS scraped_timestamp,
                CASE
                    WHEN ((scrap_dmr_brandmeister.tx ~ '^\d+(\.\d+)?$'::text) AND ((scrap_dmr_brandmeister.tx)::numeric > (0)::numeric)) THEN (scrap_dmr_brandmeister.tx)::numeric
                    ELSE NULL::numeric
                END AS frequency
           FROM public.scrap_dmr_brandmeister
        UNION ALL
         SELECT 'tetra_oevsv'::text AS network_id,
            scrap_tetra_oevsv.node,
            scrap_tetra_oevsv.callsign,
            scrap_tetra_oevsv.scraped_timestamp,
            ("substring"(scrap_tetra_oevsv.comment, '/(\d+(?:\.\d+)?)\s*$'::text))::numeric AS frequency
           FROM public.scrap_tetra_oevsv
        UNION ALL
         SELECT 'tetra_de'::text AS network_id,
            scrap_tetra_de.node,
            scrap_tetra_de.callsign,
            scrap_tetra_de.scraped_timestamp,
                CASE
                    WHEN (scrap_tetra_de.tx_freq ~ '^\d+(\.\d+)?$'::text) THEN (scrap_tetra_de.tx_freq)::numeric
                    ELSE NULL::numeric
                END AS frequency
           FROM public.scrap_tetra_de) n
  WHERE (COALESCE(n.node, ''::text) <> ''::text)
  GROUP BY n.network_id, n.node, n.callsign;


ALTER TABLE api.network_node OWNER TO vhf_owner;

--
-- Name: VIEW network_node; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.network_node IS 'Nodes listed by the monitored networks, with the last listing (ircDDB: Online), the reported TX frequency and whether it is offline now';


--
-- Name: oelink_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.oelink_status AS
 WITH latest AS (
         SELECT DISTINCT ON (scrap_oelink.callsign) scrap_oelink.callsign,
            scrap_oelink.repeater_id,
            scrap_oelink.hardware,
            scrap_oelink.scraped_timestamp
           FROM public.scrap_oelink
          WHERE (COALESCE(scrap_oelink.callsign, ''::text) <> ''::text)
          ORDER BY scrap_oelink.callsign, scrap_oelink.scraped_timestamp DESC
        )
 SELECT latest.callsign,
    'OE-LINK'::text AS network,
    concat_ws(' '::text, NULLIF(latest.repeater_id, ''::text), NULLIF(latest.hardware, ''::text)) AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.oelink_status OWNER TO vhf_owner;

--
-- Name: VIEW oelink_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.oelink_status IS 'Live status of the FM repeaters on OE-Link (active = listed within 120 minutes)';


--
-- Name: ref096_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.ref096_status AS
 WITH latest AS (
         SELECT scrap_dstar_ref096.callsign,
            max(scrap_dstar_ref096.scraped_timestamp) AS scraped_timestamp
           FROM public.scrap_dstar_ref096
          WHERE (COALESCE(scrap_dstar_ref096.callsign, ''::text) <> ''::text)
          GROUP BY scrap_dstar_ref096.callsign
        )
 SELECT l.callsign,
    'REF096'::text AS network,
    ( SELECT string_agg(DISTINCT concat_ws('>'::text, NULLIF(r.gateway_module, ''::text), r.reflector_module), ', '::text) AS string_agg
           FROM public.scrap_dstar_ref096 r
          WHERE ((r.callsign = l.callsign) AND (r.scraped_timestamp = l.scraped_timestamp))) AS text,
    ((l.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (l.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest l;


ALTER TABLE api.ref096_status OWNER TO vhf_owner;

--
-- Name: VIEW ref096_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.ref096_status IS 'Live status of the D-STAR gateways linked to the reflector REF096 (active = linked within 120 minutes)';


--
-- Name: svx_oe9_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.svx_oe9_status AS
 WITH latest AS (
         SELECT scrap_fm_svx_oe9.callsign,
            max(scrap_fm_svx_oe9.scraped_timestamp) AS scraped_timestamp
           FROM public.scrap_fm_svx_oe9
          WHERE (COALESCE(scrap_fm_svx_oe9.callsign, ''::text) <> ''::text)
          GROUP BY scrap_fm_svx_oe9.callsign
        )
 SELECT latest.callsign,
    'SVXLink OE9'::text AS network,
    ''::text AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.svx_oe9_status OWNER TO vhf_owner;

--
-- Name: VIEW svx_oe9_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.svx_oe9_status IS 'Live status of the FM nodes on the SVXLink reflector OE9 (active = listed within 120 minutes)';


--
-- Name: tetra_de_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.tetra_de_status AS
 WITH latest AS (
         SELECT scrap_tetra_de.callsign,
            max(scrap_tetra_de.scraped_timestamp) AS scraped_timestamp
           FROM public.scrap_tetra_de
          WHERE (COALESCE(scrap_tetra_de.callsign, ''::text) <> ''::text)
          GROUP BY scrap_tetra_de.callsign
        )
 SELECT latest.callsign,
    'Tetra-DE'::text AS network,
    ''::text AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.tetra_de_status OWNER TO vhf_owner;

--
-- Name: VIEW tetra_de_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.tetra_de_status IS 'Live status of the Austrian TETRA nodes on the reflectors of the Tetra Dashboard leipzig2000 (active = listed within 120 minutes)';


--
-- Name: tetra_oevsv_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.tetra_oevsv_status AS
 WITH latest AS (
         SELECT scrap_tetra_oevsv.callsign,
            max(scrap_tetra_oevsv.scraped_timestamp) AS scraped_timestamp
           FROM public.scrap_tetra_oevsv
          WHERE (COALESCE(scrap_tetra_oevsv.callsign, ''::text) <> ''::text)
          GROUP BY scrap_tetra_oevsv.callsign
        )
 SELECT latest.callsign,
    'Tetra ÖVSV'::text AS network,
    ''::text AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.tetra_oevsv_status OWNER TO vhf_owner;

--
-- Name: VIEW tetra_oevsv_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.tetra_oevsv_status IS 'Live status of the TETRA gateways on the reflector TETRA OE-MASTER (active = listed within 120 minutes)';


--
-- Name: xlx905_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.xlx905_status AS
 WITH latest AS (
         SELECT scrap_dstar_xlx905.callsign,
            max(scrap_dstar_xlx905.scraped_timestamp) AS ts
           FROM public.scrap_dstar_xlx905
          WHERE (COALESCE(scrap_dstar_xlx905.callsign, ''::text) <> ''::text)
          GROUP BY scrap_dstar_xlx905.callsign
        )
 SELECT l.callsign,
    'XLX905'::text AS network,
    ( SELECT string_agg(DISTINCT concat_ws(' '::text, NULLIF(x.dv_station, ''::text), NULLIF(x.band, ''::text)), ', '::text) AS string_agg
           FROM public.scrap_dstar_xlx905 x
          WHERE ((x.callsign = l.callsign) AND (x.scraped_timestamp = l.ts))) AS text,
    ((l.ts AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (l.ts AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest l;


ALTER TABLE api.xlx905_status OWNER TO vhf_owner;

--
-- Name: VIEW xlx905_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.xlx905_status IS 'Live status of the D-STAR repeaters on XLX905 (active = listed within 120 minutes)';


--
-- Name: ycs232_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.ycs232_status AS
 WITH latest AS (
         SELECT DISTINCT ON (scrap_c4fm_ycs232.callsign) scrap_c4fm_ycs232.callsign,
            scrap_c4fm_ycs232.repeater_id,
            scrap_c4fm_ycs232.type,
            scrap_c4fm_ycs232.scraped_timestamp
           FROM public.scrap_c4fm_ycs232
          WHERE (COALESCE(scrap_c4fm_ycs232.callsign, ''::text) <> ''::text)
          ORDER BY scrap_c4fm_ycs232.callsign, scrap_c4fm_ycs232.scraped_timestamp DESC
        )
 SELECT latest.callsign,
    'YCS232'::text AS network,
    concat_ws(' '::text, NULLIF(latest.repeater_id, ''::text), NULLIF(latest.type, ''::text)) AS text,
    ((latest.scraped_timestamp AT TIME ZONE 'UTC'::text) >= (now() - '02:00:00'::interval)) AS active,
    (latest.scraped_timestamp AT TIME ZONE 'UTC'::text) AS last_active
   FROM latest;


ALTER TABLE api.ycs232_status OWNER TO vhf_owner;

--
-- Name: VIEW ycs232_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.ycs232_status IS 'Live status of the C4FM repeaters on YCS232 (active = listed within 120 minutes)';


--
-- Name: network_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.network_status AS
 SELECT oelink_status.callsign,
    oelink_status.network,
    'fm'::text AS technology,
    oelink_status.text,
    oelink_status.active,
    oelink_status.last_active
   FROM api.oelink_status
UNION ALL
 SELECT ipsc2_status.callsign,
    ipsc2_status.network,
    'dmr'::text AS technology,
    ipsc2_status.text,
    ipsc2_status.active,
    ipsc2_status.last_active
   FROM api.ipsc2_status
UNION ALL
 SELECT ycs232_status.callsign,
    ycs232_status.network,
    'c4fm'::text AS technology,
    ycs232_status.text,
    ycs232_status.active,
    ycs232_status.last_active
   FROM api.ycs232_status
UNION ALL
 SELECT dcs009_status.callsign,
    dcs009_status.network,
    'dstar'::text AS technology,
    dcs009_status.text,
    dcs009_status.active,
    dcs009_status.last_active
   FROM api.dcs009_status
UNION ALL
 SELECT xlx905_status.callsign,
    xlx905_status.network,
    'dstar'::text AS technology,
    xlx905_status.text,
    xlx905_status.active,
    xlx905_status.last_active
   FROM api.xlx905_status
UNION ALL
 SELECT ircddb_status.callsign,
    ircddb_status.network,
    'dstar'::text AS technology,
    ircddb_status.text,
    ircddb_status.active,
    ircddb_status.last_active
   FROM api.ircddb_status
UNION ALL
 SELECT svx_oe9_status.callsign,
    svx_oe9_status.network,
    'fm'::text AS technology,
    svx_oe9_status.text,
    svx_oe9_status.active,
    svx_oe9_status.last_active
   FROM api.svx_oe9_status
UNION ALL
 SELECT tetra_oevsv_status.callsign,
    tetra_oevsv_status.network,
    'tetra'::text AS technology,
    tetra_oevsv_status.text,
    tetra_oevsv_status.active,
    tetra_oevsv_status.last_active
   FROM api.tetra_oevsv_status
UNION ALL
 SELECT brandmeister_status.callsign,
    brandmeister_status.network,
    'dmr'::text AS technology,
    brandmeister_status.text,
    brandmeister_status.active,
    brandmeister_status.last_active
   FROM api.brandmeister_status
UNION ALL
 SELECT ref096_status.callsign,
    ref096_status.network,
    'dstar'::text AS technology,
    ref096_status.text,
    ref096_status.active,
    ref096_status.last_active
   FROM api.ref096_status
UNION ALL
 SELECT tetra_de_status.callsign,
    tetra_de_status.network,
    'tetra'::text AS technology,
    tetra_de_status.text,
    tetra_de_status.active,
    tetra_de_status.last_active
   FROM api.tetra_de_status;


ALTER TABLE api.network_status OWNER TO vhf_owner;

--
-- Name: VIEW network_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.network_status IS 'Live status of the repeaters in all monitored networks (OE-Link, SVXLink OE9: FM, IPSC2, Brandmeister: DMR, YCS232: C4FM, DCS009/XLX905/REF096/ircDDB: D-STAR, Tetra ÖVSV, Tetra-DE: TETRA)';


--
-- Name: network; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.network (
    id text NOT NULL,
    label text NOT NULL,
    url text,
    technologies text[] NOT NULL,
    sort smallint DEFAULT 0 NOT NULL,
    CONSTRAINT network_id_check CHECK ((id ~ '^[a-z0-9_]+$'::text)),
    CONSTRAINT network_technologies_check CHECK (((technologies <@ ARRAY['fm'::text, 'dmr'::text, 'c4fm'::text, 'dstar'::text, 'tetra'::text]) AND (technologies <> '{}'::text[])))
);


ALTER TABLE public.network OWNER TO vhf_owner;

--
-- Name: TABLE network; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.network IS 'Networks / repeater systems whose nodes are scraped; trx.networks links transmitters to their nodes';


--
-- Name: network_unlinked; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.network_unlinked AS
 SELECT nn.network_id,
    n.label AS network,
    n.url AS network_url,
    nn.node,
    nn.callsign,
    nn.frequency AS node_frequency,
    nn.last_listed,
    c.candidates,
    nn.offline
   FROM ((api.network_node nn
     JOIN public.network n ON ((n.id = nn.network_id)))
     CROSS JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('trx_uid', t.uid, 'site_name', t.site_name, 'frequency_tx', t.frequency_tx, 'technologies', public.trx_technologies(t.*), 'fits', (public.trx_technologies(t.*) && n.technologies), 'excluded', ((t.networks ? n.id) AND ((t.networks -> n.id) = 'null'::jsonb)), 'linked_node', (t.networks ->> n.id)) ORDER BY t.site_name, t.frequency_tx) AS candidates
           FROM public.trx t
          WHERE (((t.status)::text = 'active'::text) AND (upper((t.callsign)::text) = nn.callsign))) c)
  WHERE ((nn.last_listed >= (now() - '30 days'::interval)) AND (c.candidates IS NOT NULL) AND (NOT (EXISTS ( SELECT 1
           FROM public.trx t
          WHERE (t.networks @> jsonb_build_object(nn.network_id, nn.node))))));


ALTER TABLE api.network_unlinked OWNER TO vhf_owner;

--
-- Name: VIEW network_unlinked; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.network_unlinked IS 'Nodes listed within 30 days, not linked to a transmitter, whose callsign is in trx (with candidates)';


--
-- Name: trx_network; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.trx_network AS
 SELECT t.uid AS trx_uid,
    l.key AS network_id,
    n.label AS network,
    n.url AS network_url,
    l.value AS node,
    t.site_name,
    upper((t.callsign)::text) AS callsign,
    t.frequency_tx,
    t.type_of_station,
    t.status AS trx_status,
    public.trx_technologies(t.*) AS technologies,
    nn.frequency AS node_frequency,
    nn.last_listed,
    COALESCE(((nn.last_listed >= (now() - '02:00:00'::interval)) AND (NOT nn.offline)), false) AS listed_now,
    COALESCE(nn.offline, false) AS offline
   FROM (((public.trx t
     CROSS JOIN LATERAL jsonb_each_text(t.networks) l(key, value))
     JOIN public.network n ON ((n.id = l.key)))
     LEFT JOIN api.network_node nn ON (((nn.network_id = l.key) AND (nn.node = l.value))))
  WHERE (l.value IS NOT NULL);


ALTER TABLE api.trx_network OWNER TO vhf_owner;

--
-- Name: VIEW trx_network; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.trx_network IS 'Transmitter <-> network node links (trx.networks), with the node''s last listing';


--
-- Name: networks; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.networks AS
 SELECT n.id,
    n.label,
    n.url,
    n.technologies,
    n.sort,
    ( SELECT count(*) AS count
           FROM api.trx_network tn
          WHERE (tn.network_id = n.id)) AS linked,
    ( SELECT count(*) AS count
           FROM api.network_node nn
          WHERE ((nn.network_id = n.id) AND (nn.last_listed >= (now() - '02:00:00'::interval)) AND (NOT nn.offline))) AS listed_now
   FROM public.network n;


ALTER TABLE api.networks OWNER TO vhf_owner;

--
-- Name: VIEW networks; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.networks IS 'Monitored networks with the number of linked transmitters and of nodes listed now';


--
-- Name: setting_options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.setting_options (
    uid integer NOT NULL,
    object character varying,
    filter jsonb
);


ALTER TABLE public.setting_options OWNER TO postgres;

--
-- Name: settings; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.settings AS
 SELECT setting_options.uid,
    setting_options.object,
    setting_options.filter
   FROM public.setting_options
  WHERE (setting_options.uid = 1);


ALTER TABLE api.settings OWNER TO postgres;

--
-- Name: settings2; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.settings2 AS
 SELECT setting_options.uid,
    setting_options.object,
    setting_options.filter
   FROM public.setting_options
  WHERE (setting_options.uid = 2);


ALTER TABLE api.settings2 OWNER TO vhf_owner;

--
-- Name: site; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.site (
    uid bigint NOT NULL,
    site_name character varying(100) NOT NULL,
    city character varying(100),
    longitude double precision,
    latitude double precision,
    sea_level double precision,
    locator_short character varying(6),
    locator_long character varying(20),
    geo_prefix character varying(3),
    bev_gid integer,
    geom public.geometry(Geometry,3857),
    internal character varying(1000)
);


ALTER TABLE public.site OWNER TO vhf_owner;

--
-- Name: COLUMN site.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.uid IS 'UID';


--
-- Name: COLUMN site.site_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.site_name IS 'Name of station, e.g. Grünberg';


--
-- Name: COLUMN site.city; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.city IS 'Bigger city around station (to identify station)';


--
-- Name: COLUMN site.longitude; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.longitude IS 'Longitude of station, e.g. 48. North is positive';


--
-- Name: COLUMN site.latitude; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.latitude IS 'Latitude of station, e.g. 15. East is positive';


--
-- Name: COLUMN site.sea_level; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.sea_level IS 'See level using WGS84 geoid in meter.';


--
-- Name: COLUMN site.locator_short; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.locator_short IS 'Short locator, e.g. JN78ab';


--
-- Name: COLUMN site.locator_long; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.locator_long IS 'Long locator (exact location)';


--
-- Name: COLUMN site.geo_prefix; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.geo_prefix IS 'Amateur radio prefix of Austrian location, e.g. OE3';


--
-- Name: COLUMN site.bev_gid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.bev_gid IS 'GID of BEV table (pointer to community, etc.)';


--
-- Name: COLUMN site.geom; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.geom IS 'Geometry of location';


--
-- Name: COLUMN site.internal; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.site.internal IS 'Internal comment';


--
-- Name: site; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.site AS
 SELECT site.uid,
    site.site_name,
    site.city,
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
    public.st_askml(site.geom) AS st_askml
   FROM public.site;


ALTER TABLE api.site OWNER TO vhf_owner;

--
-- Name: site_canonical; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.site_canonical AS
 WITH c AS (
         SELECT DISTINCT trx.site_name,
            upper((trx.callsign)::text) AS callsign
           FROM public.trx
          WHERE (((trx.status)::text = 'active'::text) AND ((COALESCE(trx.callsign, ''::character varying))::text <> ''::text))
        ), unique_calls AS (
         SELECT c_1.callsign
           FROM c c_1
          GROUP BY c_1.callsign
         HAVING (count(*) = 1)
        )
 SELECT c.site_name,
    COALESCE(min(c.callsign) FILTER (WHERE (c.callsign IN ( SELECT unique_calls.callsign
           FROM unique_calls))), min(c.callsign)) AS canonical_callsign
   FROM c
  GROUP BY c.site_name;


ALTER TABLE api.site_canonical OWNER TO vhf_owner;

--
-- Name: site_type; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.site_type AS
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
    public.st_askml(site.geom) AS st_askml
   FROM (public.site site
     LEFT JOIN public.trx USING (site_name))
  WHERE ((trx.status)::text = 'active'::text)
  GROUP BY site.site_name, site.city, site.longitude, site.latitude, (public.vhf_nice_geo(site.longitude)), (public.vhf_nice_geo(site.latitude)), site.sea_level, site.locator_short, site.locator_long, site.geo_prefix, site.bev_gid, site.geom;


ALTER TABLE api.site_type OWNER TO vhf_owner;

--
-- Name: trx; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.trx AS
 SELECT trx.uid,
    trx.type_of_station,
    COALESCE(public.vhf_band_name(trx.frequency_tx), public.vhf_band_name(trx.frequency_rx)) AS band,
    trx.frequency_tx,
    trx.frequency_rx,
    public.vhf_channel_name(trx.frequency_tx, trx.frequency_rx, 0) AS ch,
    public.vhf_channel_name(trx.frequency_tx, trx.frequency_rx, 1) AS ch_new,
    trx.callsign,
    trx.antenna_heigth,
    trx.site_name,
    trx.sysop,
    trx.url,
    trx.hardware,
    trx.mmdvm,
    trx.solar_power,
    trx.battery_power,
    trx.status,
    trx.fm,
    trx.fm_wakeup,
    trx.ctcss_tx,
    trx.ctcss_rx,
    trx.echolink,
    trx.echolink_id,
    trx.digital_id,
    trx.dmr,
    trx.cc,
    trx.ipsc2,
    trx.brandmeister,
    trx.c4fm,
    trx.c4fm_groups,
    trx.dstar,
    trx.dstar_rpt1,
    trx.dstar_rpt2,
    trx.tetra,
    trx.other_mode,
    trx.other_mode_name,
    trx.comment
   FROM public.trx;


ALTER TABLE api.trx OWNER TO vhf_owner;

--
-- Name: oesterreich_bev_vgd_lam; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oesterreich_bev_vgd_lam (
    gid integer NOT NULL,
    meridian smallint,
    gkz integer,
    bkz smallint,
    fa_nr smallint,
    bl_kz smallint,
    st_kz smallint,
    fl double precision,
    kg_nr character varying(6),
    kg character varying(50),
    pg character varying(50),
    pb character varying(50),
    fa character varying(50),
    gb_kz character varying(3),
    gb character varying(50),
    va_nr character varying(2),
    va character varying(50),
    bl character varying(50),
    st character varying(50),
    geom public.geometry(MultiPolygon,31287)
);


ALTER TABLE public.oesterreich_bev_vgd_lam OWNER TO postgres;

--
-- Name: trx_list; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list AS
 SELECT public.vhf_band_name(t.frequency_tx) AS band,
    public.vhf_channel_name(t.frequency_tx, t.frequency_rx, 0) AS ch,
    public.vhf_channel_name(t.frequency_tx, t.frequency_rx, 1) AS ch_new,
    t.uid,
    t.type_of_station,
    t.frequency_tx,
    t.frequency_rx,
    t.callsign,
    t.antenna_heigth,
    t.site_name,
    t.sysop,
    t.url,
    t.hardware,
    t.mmdvm,
    t.solar_power,
    t.battery_power,
    t.status,
    t.fm,
    t.fm_wakeup,
    t.ctcss_tx,
    t.ctcss_rx,
    t.echolink,
    t.echolink_id,
    t.digital_id,
    t.dmr,
    t.ipsc2,
    t.brandmeister,
    t.network_registered,
    t.c4fm,
    t.c4fm_groups,
    t.dstar,
    t.dstar_rpt1,
    NULL::character varying(1) AS dstar_rpt2,
    t.tetra,
    t.other_mode,
    t.other_mode_name,
    t.comment,
    t.created_at,
    s.city,
    s.longitude,
    s.latitude,
    s.sea_level,
    s.locator_short,
    s.locator_long,
    s.geo_prefix,
    s.bev_gid,
    s.geom,
    o.kg,
    o.pg,
    o.bl,
    t.cc,
    concat("substring"((t.callsign)::text, 3, 4), '-',
        CASE
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true)) THEN
            CASE
                WHEN ((public.vhf_band_name(t.frequency_tx))::text = '6m'::text) THEN '6'::text
                WHEN ((public.vhf_band_name(t.frequency_tx))::text = '2m'::text) THEN '2'::text
                WHEN ((public.vhf_band_name(t.frequency_tx))::text = '70cm'::text) THEN '7'::text
                WHEN ((public.vhf_band_name(t.frequency_tx))::text = '23cm'::text) THEN '3'::text
                WHEN ((public.vhf_band_name(t.frequency_tx))::text = '13cm'::text) THEN '1'::text
                ELSE '0'::text
            END
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dmr = true)) THEN 'D'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.c4fm = true)) THEN 'C'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dstar = true)) THEN 'I'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.tetra = true)) THEN 'T'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.other_mode = true)) THEN 'X'::text
            WHEN ((t.type_of_station)::text = 'atv'::text) THEN 'A'::text
            WHEN ((t.type_of_station)::text = 'digipeater'::text) THEN 'P'::text
            WHEN ((t.type_of_station)::text = 'beacon'::text) THEN 'B'::text
            ELSE 'N'::text
        END) AS label
   FROM ((public.trx t
     LEFT JOIN public.site s ON (((s.site_name)::text = (t.site_name)::text)))
     LEFT JOIN public.oesterreich_bev_vgd_lam o ON ((o.gid = s.bev_gid)))
  WHERE ((t.status)::text = 'active'::text)
  ORDER BY s.geo_prefix, t.frequency_tx;


ALTER TABLE public.trx_list OWNER TO vhf_owner;

--
-- Name: trx_list; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.trx_list AS
 SELECT trx_list.band,
    trx_list.ch,
    trx_list.ch_new,
    trx_list.uid,
    trx_list.type_of_station,
    trx_list.frequency_tx,
    trx_list.frequency_rx,
    trx_list.callsign,
    trx_list.antenna_heigth,
    trx_list.site_name,
    trx_list.sysop,
    trx_list.url,
    trx_list.hardware,
    trx_list.mmdvm,
    trx_list.solar_power,
    trx_list.battery_power,
    trx_list.status,
    trx_list.fm,
    trx_list.fm_wakeup,
    trx_list.ctcss_tx,
    trx_list.ctcss_rx,
    trx_list.echolink,
    trx_list.echolink_id,
    trx_list.digital_id,
    trx_list.dmr,
    trx_list.ipsc2,
    trx_list.brandmeister,
    trx_list.network_registered,
    trx_list.c4fm,
    trx_list.c4fm_groups,
    trx_list.dstar,
    trx_list.dstar_rpt1,
    trx_list.tetra,
    trx_list.other_mode,
    trx_list.other_mode_name,
    trx_list.comment,
    trx_list.created_at,
    trx_list.city,
    trx_list.longitude,
    trx_list.latitude,
    trx_list.sea_level,
    trx_list.locator_short,
    trx_list.locator_long,
    trx_list.geo_prefix,
    trx_list.bev_gid,
    trx_list.geom,
    trx_list.kg,
    trx_list.pg,
    trx_list.bl,
    trx_list.cc,
    trx_list.label
   FROM public.trx_list;


ALTER TABLE api.trx_list OWNER TO vhf_owner;

--
-- Name: trx_status; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.trx_status AS
 SELECT tn.trx_uid,
    tn.site_name,
    tn.callsign,
    tn.network_id,
    tn.network,
    tn.node,
    COALESCE(NULLIF(ARRAY( SELECT x.x
           FROM unnest(tn.technologies) x(x)
          WHERE (x.x = ANY (n.technologies))), '{}'::text[]), n.technologies) AS technologies,
        CASE tn.network_id
            WHEN 'xlx905'::text THEN ( SELECT x.band
               FROM public.scrap_dstar_xlx905 x
              WHERE (x.dv_station = tn.node)
              ORDER BY x.scraped_timestamp DESC
             LIMIT 1)
            WHEN 'ref096'::text THEN ( SELECT concat_ws('>'::text, NULLIF(r.gateway_module, ''::text), r.reflector_module) AS concat_ws
               FROM public.scrap_dstar_ref096 r
              WHERE (r.node = tn.node)
              ORDER BY r.scraped_timestamp DESC
             LIMIT 1)
            ELSE ns.text
        END AS text,
    tn.listed_now AS active,
    tn.last_listed AS last_active,
    tn.offline
   FROM ((api.trx_network tn
     JOIN public.network n ON ((n.id = tn.network_id)))
     LEFT JOIN api.network_status ns ON (((ns.callsign = tn.callsign) AND (ns.network = tn.network))))
  WHERE (((tn.trx_status)::text = 'active'::text) AND (tn.last_listed IS NOT NULL));


ALTER TABLE api.trx_status OWNER TO vhf_owner;

--
-- Name: VIEW trx_status; Type: COMMENT; Schema: api; Owner: vhf_owner
--

COMMENT ON VIEW api.trx_status IS 'Network status per transmitter: one row per link in trx.networks of an active transmitter (active = the node is listed now)';


--
-- Name: trx_type; Type: VIEW; Schema: api; Owner: vhf_owner
--

CREATE VIEW api.trx_type AS
 SELECT trx.site_name,
    (((trx.type_of_station)::text = 'repeater_voice'::text) AND (trx.fm IS TRUE)) AS fm,
    (((trx.type_of_station)::text = 'repeater_voice'::text) AND (trx.dmr IS TRUE)) AS dmr,
    (((trx.type_of_station)::text = 'repeater_voice'::text) AND (trx.c4fm IS TRUE)) AS c4fm,
    (((trx.type_of_station)::text = 'repeater_voice'::text) AND (trx.dstar IS TRUE)) AS dstar,
    (((trx.type_of_station)::text = 'repeater_voice'::text) AND (trx.tetra IS TRUE)) AS tetra,
    ((trx.type_of_station)::text = 'beacon'::text) AS beacon,
    ((trx.type_of_station)::text = 'digipeater'::text) AS digipeater,
    ((trx.type_of_station)::text = 'atv'::text) AS atv,
    COALESCE(public.vhf_band_name(trx.frequency_tx), public.vhf_band_name(trx.frequency_rx)) AS band,
    trx.frequency_tx,
    trx.frequency_rx,
    public.vhf_channel_name(trx.frequency_tx, trx.frequency_rx, 0) AS ch,
    public.vhf_channel_name(trx.frequency_tx, trx.frequency_rx, 1) AS ch_new,
    trx.callsign,
    trx.antenna_heigth,
    trx.sysop,
    trx.url,
    trx.hardware,
    trx.mmdvm,
    trx.solar_power,
    trx.battery_power,
    trx.fm_wakeup,
    trx.ctcss_tx,
    trx.ctcss_rx,
    trx.echolink,
    trx.echolink_id,
    trx.digital_id,
    trx.cc,
    trx.ipsc2,
    trx.brandmeister,
    trx.c4fm_groups,
    trx.dstar_rpt1,
    trx.other_mode_name,
    trx.comment,
    trx.uid AS trx_uid
   FROM public.trx
  WHERE ((trx.status)::text = 'active'::text);


ALTER TABLE api.trx_type OWNER TO vhf_owner;

--
-- Name: bands; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.bands (
    uid integer NOT NULL,
    band_name character varying(30),
    frequency_from double precision,
    frequency_to double precision,
    common_band boolean
);


ALTER TABLE public.bands OWNER TO vhf_owner;

--
-- Name: COLUMN bands.common_band; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.bands.common_band IS 'Band available on all common transceivers';


--
-- Name: band_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.band_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.band_uid_seq OWNER TO vhf_owner;

--
-- Name: band_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.band_uid_seq OWNED BY public.bands.uid;


--
-- Name: beacon_import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.beacon_import (
    uid integer NOT NULL,
    frequency_tx double precision,
    callsign character varying,
    location_import character varying,
    locator_import character varying,
    sea_level_import integer,
    power character varying,
    sysop character varying,
    footnotes character varying,
    type_of_station character varying DEFAULT 'beacon'::character varying
);


ALTER TABLE public.beacon_import OWNER TO vhf_owner;

--
-- Name: COLUMN beacon_import.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.beacon_import.uid IS 'UID';


--
-- Name: beacon_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.beacon_import_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.beacon_import_uid_seq OWNER TO vhf_owner;

--
-- Name: beacon_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.beacon_import_uid_seq OWNED BY public.beacon_import.uid;


--
-- Name: bl_kz_prefix; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.bl_kz_prefix (
    uid integer NOT NULL,
    bl_kz smallint NOT NULL,
    prefix character varying(3) NOT NULL,
    manager character varying(10)
);


ALTER TABLE public.bl_kz_prefix OWNER TO vhf_owner;

--
-- Name: TABLE bl_kz_prefix; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.bl_kz_prefix IS 'Mapping between BEV Bundesländerkennzeichen and amateur radio prefix';


--
-- Name: COLUMN bl_kz_prefix.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.bl_kz_prefix.uid IS 'UID';


--
-- Name: COLUMN bl_kz_prefix.bl_kz; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.bl_kz_prefix.bl_kz IS 'Austria regional ID according to BEV';


--
-- Name: COLUMN bl_kz_prefix.prefix; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.bl_kz_prefix.prefix IS 'Prefix of Austrian amateur radio callsigns in this area';


--
-- Name: COLUMN bl_kz_prefix.manager; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.bl_kz_prefix.manager IS 'VHF-Manager of region (UKW Referent im LV)';


--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.bl_kz_prefix_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bl_kz_prefix_uid_seq OWNER TO vhf_owner;

--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.bl_kz_prefix_uid_seq OWNED BY public.bl_kz_prefix.uid;


--
-- Name: repeater_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.repeater_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.repeater_uid_seq OWNER TO vhf_owner;

--
-- Name: repeater_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.repeater_uid_seq OWNED BY public.trx.uid;


--
-- Name: direct_channels; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.direct_channels (
    uid bigint DEFAULT nextval('public.repeater_uid_seq'::regclass) NOT NULL,
    type_of_station character varying(50) DEFAULT 'repeater_voice'::character varying NOT NULL,
    frequency_tx double precision,
    frequency_rx double precision,
    callsign character varying(10),
    antenna_heigth double precision,
    site_name character varying(100),
    sysop character varying(10),
    url character varying(500),
    hardware character varying(100),
    mmdvm boolean,
    solar_power boolean,
    battery_power boolean,
    status character varying,
    fm boolean,
    fm_wakeup character varying(50),
    ctcss_tx double precision,
    ctcss_rx double precision,
    echolink boolean,
    echolink_id bigint,
    digital_id bigint,
    dmr boolean,
    ipsc2 boolean,
    brandmeister boolean,
    network_registered boolean,
    c4fm boolean,
    c4fm_groups character varying(30),
    dstar boolean,
    dstar_rpt1 character varying(1),
    dstar_rpt2 character varying(1),
    tetra boolean,
    other_mode boolean,
    other_mode_name character varying(50),
    comment character varying(1000),
    internal character varying(3000),
    created_at timestamp with time zone DEFAULT now(),
    cc integer
);


ALTER TABLE public.direct_channels OWNER TO vhf_owner;

--
-- Name: COLUMN direct_channels.frequency_tx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.frequency_tx IS 'in MHz';


--
-- Name: COLUMN direct_channels.frequency_rx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.frequency_rx IS 'in MHz';


--
-- Name: COLUMN direct_channels.callsign; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN direct_channels.antenna_heigth; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN direct_channels.site_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.site_name IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN direct_channels.sysop; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN direct_channels.url; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN direct_channels.hardware; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.hardware IS 'Hardware of station';


--
-- Name: COLUMN direct_channels.mmdvm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN direct_channels.solar_power; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN direct_channels.battery_power; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN direct_channels.status; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN direct_channels.fm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.fm IS 'Analogue FM station';


--
-- Name: COLUMN direct_channels.fm_wakeup; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.fm_wakeup IS 'Tone or DTMF needed for activation of repeater, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN direct_channels.ctcss_tx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN direct_channels.ctcss_rx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN direct_channels.echolink; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN direct_channels.echolink_id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN direct_channels.digital_id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN direct_channels.dmr; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN direct_channels.ipsc2; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN direct_channels.brandmeister; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN direct_channels.network_registered; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN direct_channels.c4fm; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN direct_channels.c4fm_groups; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN direct_channels.dstar; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN direct_channels.dstar_rpt1; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN direct_channels.dstar_rpt2; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN direct_channels.tetra; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.tetra IS 'True if Tetra station';


--
-- Name: COLUMN direct_channels.other_mode; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN direct_channels.other_mode_name; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN direct_channels.comment; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.comment IS 'Public visible comment';


--
-- Name: COLUMN direct_channels.internal; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN direct_channels.created_at; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN direct_channels.cc; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.direct_channels.cc IS 'Color Code (default DMR code is 1)';


--
-- Name: chirp_fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.chirp_fm AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Location",
    foobar."Name",
    foobar."Frequency",
    foobar."Duplex",
    foobar."Offset",
    foobar."Tone",
    foobar."rToneFreq",
    foobar."cToneFreq",
    foobar."DtcsCode",
    foobar."DtcsPolarity",
    foobar."Mode",
    foobar."TStep",
    foobar."Skip",
    foobar."Comment",
    foobar."URCALL",
    foobar."RPT1CALL",
    foobar."RPT2CALL",
    foobar."DVCODE"
   FROM (( SELECT "substring"((t.site_name)::text, 1, 6) AS "Name",
            t.frequency_tx AS "Frequency",
            'split'::character varying AS "Duplex",
            t.frequency_rx AS "Offset",
            public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx) AS "Tone",
            public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx) AS "rToneFreq",
            public.vhf_chirp_ctonefreq(t.ctcss_tx, t.ctcss_rx) AS "cToneFreq",
            '023'::character varying AS "DtcsCode",
            'NN'::character varying AS "DtcsPolarity",
            'FM'::character varying AS "Mode",
            '25.0'::character varying AS "TStep",
            ''::text AS "Skip",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx)) AS "Comment",
            ''::text AS "URCALL",
            ''::text AS "RPT1CALL",
            ''::text AS "RPT2CALL",
            ''::text AS "DVCODE"
           FROM public.direct_channels t
          WHERE (((t.type_of_station)::text = 'direct'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1)) AS "Name",
            t.frequency_tx AS "Frequency",
            'split'::character varying AS "Duplex",
            t.frequency_rx AS "Offset",
            public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx) AS "Tone",
            public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx) AS "rToneFreq",
            public.vhf_chirp_ctonefreq(t.ctcss_tx, t.ctcss_rx) AS "cToneFreq",
            '023'::character varying AS "DtcsCode",
            'NN'::character varying AS "DtcsPolarity",
            'FM'::character varying AS "Mode",
            '25.0'::character varying AS "TStep",
            ''::text AS "Skip",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx)) AS "Comment",
            ''::text AS "URCALL",
            ''::text AS "RPT1CALL",
            ''::text AS "RPT2CALL",
            ''::text AS "DVCODE"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar;


ALTER TABLE public.chirp_fm OWNER TO vhf_owner;

--
-- Name: chirp_fm_short; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.chirp_fm_short AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Location",
    foobar."Name",
    foobar."Frequency",
    foobar."Duplex",
    foobar."Offset",
    foobar."Tone",
    foobar."rToneFreq",
    foobar."cToneFreq",
    foobar."DtcsCode",
    foobar."DtcsPolarity",
    foobar."Mode",
    foobar."TStep",
    foobar."Skip",
    foobar."Comment",
    foobar."URCALL",
    foobar."RPT1CALL",
    foobar."RPT2CALL",
    foobar."DVCODE"
   FROM (( SELECT concat("substring"((t.callsign)::text, 3, 4), "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1)) AS "Name",
            t.frequency_tx AS "Frequency",
            'split'::character varying AS "Duplex",
            t.frequency_rx AS "Offset",
            public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx) AS "Tone",
            public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx) AS "rToneFreq",
            public.vhf_chirp_ctonefreq(t.ctcss_tx, t.ctcss_rx) AS "cToneFreq",
            '023'::character varying AS "DtcsCode",
            'NN'::character varying AS "DtcsPolarity",
            'FM'::character varying AS "Mode",
            '25.0'::character varying AS "TStep",
            ''::text AS "Skip",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx)) AS "Comment",
            ''::text AS "URCALL",
            ''::text AS "RPT1CALL",
            ''::text AS "RPT2CALL",
            ''::text AS "DVCODE"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT "substring"((t.site_name)::text, 1, 6) AS "Name",
            t.frequency_tx AS "Frequency",
            'split'::character varying AS "Duplex",
            t.frequency_rx AS "Offset",
            public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx) AS "Tone",
            public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx) AS "rToneFreq",
            public.vhf_chirp_ctonefreq(t.ctcss_tx, t.ctcss_rx) AS "cToneFreq",
            '023'::character varying AS "DtcsCode",
            'NN'::character varying AS "DtcsPolarity",
            'FM'::character varying AS "Mode",
            '25.0'::character varying AS "TStep",
            ''::text AS "Skip",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx)) AS "Comment",
            ''::text AS "URCALL",
            ''::text AS "RPT1CALL",
            ''::text AS "RPT2CALL",
            ''::text AS "DVCODE"
           FROM public.direct_channels t
          WHERE (((t.type_of_station)::text = 'direct'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar;


ALTER TABLE public.chirp_fm_short OWNER TO vhf_owner;

--
-- Name: dhm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dhm (
    rid integer NOT NULL,
    rast public.raster
);


ALTER TABLE public.dhm OWNER TO postgres;

--
-- Name: dhm_rid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dhm_rid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dhm_rid_seq OWNER TO postgres;

--
-- Name: dhm_rid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dhm_rid_seq OWNED BY public.dhm.rid;


--
-- Name: digital_repeater_id_import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.digital_repeater_id_import (
    uid bigint NOT NULL,
    callsign character varying(10),
    station character varying,
    digital_id integer
);


ALTER TABLE public.digital_repeater_id_import OWNER TO vhf_owner;

--
-- Name: COLUMN digital_repeater_id_import.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.digital_repeater_id_import.uid IS 'UID';


--
-- Name: digital_repeater_id_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.digital_repeater_id_import_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.digital_repeater_id_import_uid_seq OWNER TO vhf_owner;

--
-- Name: digital_repeater_id_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.digital_repeater_id_import_uid_seq OWNED BY public.digital_repeater_id_import.uid;


--
-- Name: dmr_groups; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.dmr_groups (
    uid smallint NOT NULL,
    number integer NOT NULL,
    id integer NOT NULL,
    "Type" character varying(10) DEFAULT 'Group'::character varying NOT NULL,
    "Name" character varying(10) NOT NULL
);


ALTER TABLE public.dmr_groups OWNER TO vhf_owner;

--
-- Name: COLUMN dmr_groups.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dmr_groups.uid IS 'UID';


--
-- Name: COLUMN dmr_groups.number; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dmr_groups.number IS 'index';


--
-- Name: COLUMN dmr_groups.id; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dmr_groups.id IS 'DMR ID';


--
-- Name: COLUMN dmr_groups."Type"; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dmr_groups."Type" IS 'Private/Group';


--
-- Name: COLUMN dmr_groups."Name"; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dmr_groups."Name" IS 'Usage';


--
-- Name: dmr-groups_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public."dmr-groups_uid_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."dmr-groups_uid_seq" OWNER TO vhf_owner;

--
-- Name: dmr-groups_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public."dmr-groups_uid_seq" OWNED BY public.dmr_groups.uid;


--
-- Name: dstar_at_import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.dstar_at_import (
    uid integer NOT NULL,
    callsign character varying,
    site character varying,
    frequency_tx double precision,
    shift character varying,
    mode character varying,
    hardware character varying,
    rpt1 character varying,
    rpt2 character varying
);


ALTER TABLE public.dstar_at_import OWNER TO vhf_owner;

--
-- Name: COLUMN dstar_at_import.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.dstar_at_import.uid IS 'UID';


--
-- Name: dstar-import_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public."dstar-import_uid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."dstar-import_uid_seq" OWNER TO vhf_owner;

--
-- Name: dstar-import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public."dstar-import_uid_seq" OWNED BY public.dstar_at_import.uid;


--
-- Name: dstar-oevsv-import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public."dstar-oevsv-import" (
    uid integer NOT NULL,
    id real,
    country character varying,
    callsign character varying,
    band character varying,
    datetime character varying,
    linkduration character varying,
    module character varying,
    ip character varying
);


ALTER TABLE public."dstar-oevsv-import" OWNER TO vhf_owner;

--
-- Name: COLUMN "dstar-oevsv-import".uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public."dstar-oevsv-import".uid IS 'UID';


--
-- Name: dstar-oevsv-import_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public."dstar-oevsv-import_uid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."dstar-oevsv-import_uid_seq" OWNER TO vhf_owner;

--
-- Name: dstar-oevsv-import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public."dstar-oevsv-import_uid_seq" OWNED BY public."dstar-oevsv-import".uid;


--
-- Name: echolink-import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public."echolink-import" (
    uid integer NOT NULL,
    callsign character varying,
    welcome character varying,
    status character varying,
    "time" character varying,
    echolink_id integer
);


ALTER TABLE public."echolink-import" OWNER TO vhf_owner;

--
-- Name: COLUMN "echolink-import".uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public."echolink-import".uid IS 'UID';


--
-- Name: echolink_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.echolink_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.echolink_uid_seq OWNER TO vhf_owner;

--
-- Name: echolink_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.echolink_uid_seq OWNED BY public."echolink-import".uid;


--
-- Name: gd77; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.gd77 AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Number",
    foobar."Name",
    foobar."Rx Freq",
    foobar."Tx Freq",
    foobar."Ch Mode",
    foobar."Power",
    foobar."Rx Tone",
    foobar."Tx Tone",
    foobar."Color Code",
    foobar."Rx Group List",
    foobar."Contact",
    foobar."Repeater Slot"
   FROM (( SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1)) AS "Name",
            t.frequency_tx AS "Rx Freq",
            t.frequency_rx AS "Tx Freq",
            'Analog'::text AS "Ch Mode",
            'High'::text AS "Power",
            t.ctcss_tx AS "Rx Tone",
            t.ctcss_rx AS "Tx Tone",
            0 AS "Color Code",
            1 AS "Rx Group List",
            1 AS "Contact",
            1 AS "Repeater Slot"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1), '-D1') AS "Name",
            t.frequency_tx AS "Rx Freq",
            t.frequency_rx AS "Tx Freq",
            'Digital'::text AS "Ch Mode",
            'High'::text AS "Power",
            NULL::double precision AS "Rx Tone",
            NULL::double precision AS "Tx Tone",
            1 AS "Color Code",
            1 AS "Rx Group List",
            8 AS "Contact",
            1 AS "Repeater Slot"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dmr = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1), '-D2') AS "Name",
            t.frequency_tx AS "Rx Freq",
            t.frequency_rx AS "Tx Freq",
            'Digital'::text AS "Ch Mode",
            'High'::text AS "Power",
            NULL::double precision AS "Rx Tone",
            NULL::double precision AS "Tx Tone",
            1 AS "Color Code",
            1 AS "Rx Group List",
            10 AS "Contact",
            2 AS "Repeater Slot"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dmr = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar
  ORDER BY foobar."Name";


ALTER TABLE public.gd77 OWNER TO vhf_owner;

--
-- Name: gd77_groups; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.gd77_groups AS
 SELECT d.number AS "Number",
    d."Name",
    d.id AS "Call ID",
    concat(d."Type", ' Call') AS "Type",
    'None'::text AS "Ring Style",
    'On'::text AS "Call Receive Tone"
   FROM public.dmr_groups d
  ORDER BY d.number;


ALTER TABLE public.gd77_groups OWNER TO vhf_owner;

--
-- Name: ic9700_dr; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.ic9700_dr AS
 SELECT '1'::text AS "Group No",
    'Austria'::text AS "Group Name",
    public.vhf_nice_display(t.site_name) AS "Name",
        CASE
            WHEN (t.dstar = true) THEN concat(t.callsign, ' ', t.dstar_rpt1)
            ELSE ''::text
        END AS "Sub Name",
        CASE
            WHEN (t.dstar = true) THEN concat(t.callsign, ' ', t.dstar_rpt1)
            ELSE ''::text
        END AS "Repeater Call Sign",
        CASE
            WHEN (t.dstar = true) THEN concat(t.callsign, ' ', t.dstar_rpt2)
            ELSE ''::text
        END AS "Gateway Call Sign",
    ''::text AS "Gateway IP Address",
    t.frequency_tx AS "Frequency",
    'DUP-'::text AS "Dup",
    (round(((t.frequency_tx - t.frequency_rx) * (1000)::double precision)) / (1000)::double precision) AS "Offset",
        CASE
            WHEN (t.fm = true) THEN 'FM'::text
            ELSE 'DV'::text
        END AS "Mode",
        CASE
            WHEN ((t.ctcss_tx IS NOT NULL) AND (t.ctcss_rx IS NULL)) THEN 'TSQL'::text
            WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
            ELSE 'None'::text
        END AS "TONE",
        CASE
            WHEN (t.ctcss_rx IS NULL) THEN '162.2 Hz'::text
            ELSE concat(to_char(t.ctcss_rx, '999.9'::text), ' Hz')
        END AS "Repeater Tone",
        CASE
            WHEN (t.dstar = true) THEN 'YES'::text
            ELSE ''::text
        END AS "RPT1USE",
    'Exact'::text AS "Position",
    s.latitude AS "Latitude",
    s.longitude AS "Longitude",
    '+1:00'::text AS "UTC Offset"
   FROM (public.trx t
     LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND ((t.fm = true) OR (t.dstar = true)) AND ((t.status)::text = 'active'::text))
  ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx));


ALTER TABLE public.ic9700_dr OWNER TO vhf_owner;

--
-- Name: import_hamnet_site; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.import_hamnet_site (
    uid bigint NOT NULL,
    id integer,
    "Name" character varying,
    callsign character varying,
    longitude double precision,
    latitude double precision,
    elevation integer,
    ground_asl integer,
    no_check integer,
    radioparam character varying,
    inactive integer,
    newcover integer,
    hascover integer,
    "Comment" character varying,
    maintainer character varying,
    rw_maint integer,
    editor character varying,
    edited character varying,
    "Version" integer,
    deleted integer,
    sea_level double precision,
    locator_short character varying(6),
    locator_long character varying(20),
    geo_prefix character varying(3),
    bev_gid integer,
    geom public.geometry(Geometry,3857),
    dummy character varying
);


ALTER TABLE public.import_hamnet_site OWNER TO vhf_owner;

--
-- Name: COLUMN import_hamnet_site.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.import_hamnet_site.uid IS 'UID';


--
-- Name: import_hamnet_site_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.import_hamnet_site_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_hamnet_site_uid_seq OWNER TO vhf_owner;

--
-- Name: import_hamnet_site_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.import_hamnet_site_uid_seq OWNED BY public.import_hamnet_site.uid;


--
-- Name: licenses; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.licenses (
    uid bigint NOT NULL,
    callsign character varying(10),
    suffix character varying(7) NOT NULL,
    prefix character varying(3) NOT NULL,
    name_address character varying(200),
    issue character varying(30),
    created_at timestamp with time zone DEFAULT now(),
    internal character varying(3000),
    class integer
);


ALTER TABLE public.licenses OWNER TO vhf_owner;

--
-- Name: COLUMN licenses.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.uid IS 'UID';


--
-- Name: COLUMN licenses.callsign; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.callsign IS 'Callsign in upper case letters';


--
-- Name: COLUMN licenses.suffix; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.suffix IS 'Suffix of callsign (eg. AAA)';


--
-- Name: COLUMN licenses.prefix; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.prefix IS 'Prefix of callsign, e.g. OE1';


--
-- Name: COLUMN licenses.name_address; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.name_address IS 'Name and address of licencee';


--
-- Name: COLUMN licenses.issue; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.issue IS 'Issue of register (e.g. 2021-09)';


--
-- Name: COLUMN licenses.created_at; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN licenses.internal; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.internal IS 'Internal note';


--
-- Name: COLUMN licenses.class; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.licenses.class IS 'Lic classe (e.g. 1)';


--
-- Name: licenses_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.licenses_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.licenses_uid_seq OWNER TO vhf_owner;

--
-- Name: licenses_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.licenses_uid_seq OWNED BY public.licenses.uid;


--
-- Name: oesterreich_bev_vgd_lam_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oesterreich_bev_vgd_lam_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oesterreich_bev_vgd_lam_gid_seq OWNER TO postgres;

--
-- Name: oesterreich_bev_vgd_lam_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oesterreich_bev_vgd_lam_gid_seq OWNED BY public.oesterreich_bev_vgd_lam.gid;


--
-- Name: packet_import; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.packet_import (
    uid integer NOT NULL,
    callsign character varying(6),
    frequency_rx double precision,
    frequency_tx double precision,
    location character varying(19),
    locator_import character varying(6),
    sea_level_import integer,
    sysop character varying(6),
    notes character varying(13),
    type_of_station character varying DEFAULT 'packet_radio'::character varying,
    other_mode boolean DEFAULT true,
    other_mode_name character varying,
    comment character varying
);


ALTER TABLE public.packet_import OWNER TO vhf_owner;

--
-- Name: packet_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.packet_import_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.packet_import_uid_seq OWNER TO vhf_owner;

--
-- Name: packet_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.packet_import_uid_seq OWNED BY public.packet_import.uid;


--
-- Name: rfinder_fr; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.rfinder_fr AS
 SELECT foobar."Indicatif",
    foobar."QTH",
    foobar."Dépt",
    foobar."Locator",
    foobar."Distance",
    foobar."Azimut",
    foobar."Alt. (m)",
    foobar."Ps(W)",
    foobar."Antenne",
    foobar."Mode",
    foobar."Etat",
    foobar."Resp",
    foobar."Frq Tx",
    foobar."Bde Tx",
    foobar."Frq Rx",
    foobar."Bde Rx",
    foobar."Fonct./Dplx",
    foobar."Loc.étendu",
    foobar."CTCSS",
    foobar."Loc.publié",
    foobar."Type",
    foobar."Add/Bal.",
    foobar."Plauralité"
   FROM ( SELECT t.callsign AS "Indicatif",
            t.site_name AS "QTH",
            s.geo_prefix AS "Dépt",
            s.locator_short AS "Locator",
            NULL::double precision AS "Distance",
            NULL::double precision AS "Azimut",
            s.sea_level AS "Alt. (m)",
            NULL::double precision AS "Ps(W)",
            ''::text AS "Antenne",
            'FM'::text AS "Mode",
            'Actif'::text AS "Etat",
            t.sysop AS "Resp",
            t.frequency_tx AS "Frq Tx",
            public.vhf_band_name(t.frequency_tx) AS "Bde Tx",
            t.frequency_rx AS "Frq Rx",
            public.vhf_band_name(t.frequency_rx) AS "Bde Rx",
            (round(((t.frequency_rx - t.frequency_rx) * (10)::double precision)) / (10)::double precision) AS "Fonct./Dplx",
            s.locator_long AS "Loc.étendu",
            t.ctcss_rx AS "CTCSS",
            s.locator_long AS "Loc.publié",
            'Analogique'::text AS "Type",
            ''::text AS "Add/Bal.",
            ''::text AS "Plauralité"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
        UNION ALL
         SELECT t.callsign AS "Indicatif",
            t.site_name AS "QTH",
            s.geo_prefix AS "Dépt",
            s.locator_short AS "Locator",
            NULL::double precision AS "Distance",
            NULL::double precision AS "Azimut",
            s.sea_level AS "Alt. (m)",
            NULL::double precision AS "Ps(W)",
            ''::text AS "Antenne",
            'DMR'::text AS "Mode",
            'Actif'::text AS "Etat",
            t.sysop AS "Resp",
            t.frequency_tx AS "Frq Tx",
            public.vhf_band_name(t.frequency_tx) AS "Bde Tx",
            t.frequency_rx AS "Frq Rx",
            public.vhf_band_name(t.frequency_rx) AS "Bde Rx",
            (round(((t.frequency_rx - t.frequency_rx) * (10)::double precision)) / (10)::double precision) AS "Fonct./Dplx",
            s.locator_long AS "Loc.étendu",
            NULL::double precision AS "CTCSS",
            s.locator_long AS "Loc.publié",
            'Numérique'::text AS "Type",
            ''::text AS "Add/Bal.",
            ''::text AS "Plauralité"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dmr = true) AND ((t.status)::text = 'active'::text))
        UNION ALL
         SELECT t.callsign AS "Indicatif",
            t.site_name AS "QTH",
            s.geo_prefix AS "Dépt",
            s.locator_short AS "Locator",
            NULL::double precision AS "Distance",
            NULL::double precision AS "Azimut",
            s.sea_level AS "Alt. (m)",
            NULL::double precision AS "Ps(W)",
            ''::text AS "Antenne",
            'C4FM'::text AS "Mode",
            'Actif'::text AS "Etat",
            t.sysop AS "Resp",
            t.frequency_tx AS "Frq Tx",
            public.vhf_band_name(t.frequency_tx) AS "Bde Tx",
            t.frequency_rx AS "Frq Rx",
            public.vhf_band_name(t.frequency_rx) AS "Bde Rx",
            (round(((t.frequency_rx - t.frequency_rx) * (10)::double precision)) / (10)::double precision) AS "Fonct./Dplx",
            s.locator_long AS "Loc.étendu",
            NULL::double precision AS "CTCSS",
            s.locator_long AS "Loc.publié",
            'Numérique'::text AS "Type",
            ''::text AS "Add/Bal.",
            ''::text AS "Plauralité"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.c4fm = true) AND ((t.status)::text = 'active'::text))
        UNION ALL
         SELECT t.callsign AS "Indicatif",
            t.site_name AS "QTH",
            s.geo_prefix AS "Dépt",
            s.locator_short AS "Locator",
            NULL::double precision AS "Distance",
            NULL::double precision AS "Azimut",
            s.sea_level AS "Alt. (m)",
            NULL::double precision AS "Ps(W)",
            ''::text AS "Antenne",
            'DSTAR'::text AS "Mode",
            'Actif'::text AS "Etat",
            t.sysop AS "Resp",
            t.frequency_tx AS "Frq Tx",
            public.vhf_band_name(t.frequency_tx) AS "Bde Tx",
            t.frequency_rx AS "Frq Rx",
            public.vhf_band_name(t.frequency_rx) AS "Bde Rx",
            (round(((t.frequency_rx - t.frequency_rx) * (10)::double precision)) / (10)::double precision) AS "Fonct./Dplx",
            s.locator_long AS "Loc.étendu",
            NULL::double precision AS "CTCSS",
            s.locator_long AS "Loc.publié",
            'Numérique'::text AS "Type",
            ''::text AS "Add/Bal.",
            ''::text AS "Plauralité"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dstar = true) AND ((t.status)::text = 'active'::text))) foobar;


ALTER TABLE public.rfinder_fr OWNER TO vhf_owner;

--
-- Name: rt_ic9700_dr; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.rt_ic9700_dr AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel Number",
    foobar."Receive Frequency",
    foobar."Transmit Frequency",
    foobar."Offset Frequency",
    foobar."Offset Direction",
    foobar."Repeater Use",
    foobar."Operating Mode",
    foobar."Name",
    foobar."Sub Name",
    foobar."Tone Mode",
    foobar."CTCSS",
    foobar."IP Address",
    foobar."Rpt-1 CallSign",
    foobar."Rpt-2 CallSign",
    foobar."LatLng",
    foobar."Latitude",
    foobar."Longitude",
    foobar."UTC Offset",
    foobar."Bank",
    foobar."Comment",
    foobar."Dummy"
   FROM (( SELECT t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            ' '::text AS "Offset Frequency",
            'DUP-'::text AS "Offset Direction",
            'On'::text AS "Repeater Use",
            'DV'::text AS "Operating Mode",
            public.vhf_nice_display(t.site_name) AS "Name",
            concat(t.callsign, ' ', t.dstar_rpt1) AS "Sub Name",
            'None'::text AS "Tone Mode",
            '67.0 Hz'::text AS "CTCSS",
            ''::text AS "IP Address",
            concat(t.callsign, ' ', t.dstar_rpt1) AS "Rpt-1 CallSign",
            concat(t.callsign, ' ', t.dstar_rpt2) AS "Rpt-2 CallSign",
            'Exact'::text AS "LatLng",
            concat(public.vhf_nice_geo_dms(s.latitude), 'N') AS "Latitude",
            concat(public.vhf_nice_geo_dms(s.longitude), 'E') AS "Longitude",
            '+01:00'::text AS "UTC Offset",
            '1: Austria'::text AS "Bank",
            ''::text AS "Comment",
            ''::text AS "Dummy"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dstar = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            ' '::text AS "Offset Frequency",
            'DUP-'::text AS "Offset Direction",
            'On'::text AS "Repeater Use",
            'FM'::text AS "Operating Mode",
            public.vhf_nice_display(t.site_name) AS "Name",
            (t.callsign)::text AS "Sub Name",
                CASE
                    WHEN ((t.ctcss_tx IS NOT NULL) AND (t.ctcss_rx IS NULL)) THEN 'TSQL'::text
                    WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
                    ELSE 'None'::text
                END AS "Tone Mode",
                CASE
                    WHEN (t.ctcss_rx IS NULL) THEN '162.2 Hz'::text
                    ELSE concat(to_char(t.ctcss_rx, '999.9'::text), ' Hz')
                END AS "CTCSS",
            ''::text AS "IP Address",
            ''::text AS "Rpt-1 CallSign",
            ''::text AS "Rpt-2 CallSign",
            'Exact'::text AS "LatLng",
            concat(public.vhf_nice_geo_dms(s.latitude), 'N') AS "Latitude",
            concat(public.vhf_nice_geo_dms(s.longitude), 'E') AS "Longitude",
            '+01:00'::text AS "UTC Offset",
            '1: Austria'::text AS "Bank",
            ''::text AS "Comment",
            ''::text AS "Dummy"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
          ORDER BY t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar;


ALTER TABLE public.rt_ic9700_dr OWNER TO vhf_owner;

--
-- Name: rt_ic9700_fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.rt_ic9700_fm AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel Number",
    foobar."Receive Frequency",
    foobar."Transmit Frequency",
    foobar."Offset Frequency",
    foobar."Offset Direction",
    foobar."Operating Mode",
    foobar."Data Mode",
    foobar."Filter",
    foobar."Name",
    foobar."Tone Mode",
    foobar."CTCSS",
    foobar."Rx CTCSS",
    foobar."DCS",
    foobar."DCS Polarity",
    foobar."Scan Select",
    foobar."Digital Squelch",
    foobar."Digital Code",
    foobar."Your Callsign",
    foobar."Rpt-1 CallSign",
    foobar."Rpt-2 CallSign",
    foobar."Comment",
    foobar."Dummy"
   FROM ( SELECT t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            ' '::text AS "Offset Frequency",
            'DUP-'::text AS "Offset Direction",
            'FM'::text AS "Operating Mode",
            ''::text AS "Data Mode",
            '1'::text AS "Filter",
            (public.vhf_nice_display(t.site_name))::text AS "Name",
                CASE
                    WHEN ((t.ctcss_tx IS NOT NULL) AND (t.ctcss_rx IS NULL)) THEN 'TSQL'::text
                    WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
                    ELSE 'None'::text
                END AS "Tone Mode",
                CASE
                    WHEN (t.ctcss_rx IS NULL) THEN ''::text
                    ELSE concat(to_char(t.ctcss_rx, '999.9'::text), ' Hz')
                END AS "CTCSS",
                CASE
                    WHEN (t.ctcss_tx IS NULL) THEN ''::text
                    ELSE concat(to_char(t.ctcss_tx, '999.9'::text), ' Hz')
                END AS "Rx CTCSS",
            '023'::text AS "DCS",
            'Both N'::text AS "DCS Polarity",
            ''::text AS "Scan Select",
            'Off'::text AS "Digital Squelch",
            '0'::text AS "Digital Code",
            'CQCQCQ'::text AS "Your Callsign",
            ''::text AS "Rpt-1 CallSign",
            ''::text AS "Rpt-2 CallSign",
            concat(t.callsign, ' ', public.vhf_nice_display(s.city), ' ', public.vhf_nice_display(t.site_name)) AS "Comment",
            ''::text AS "Dummy"
           FROM (public.trx t
             LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
          ORDER BY ROW(public.vhf_band_name(t.frequency_tx), t.callsign)) foobar;


ALTER TABLE public.rt_ic9700_fm OWNER TO vhf_owner;

--
-- Name: scrap_c4fm_ycs232_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_c4fm_ycs232_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_c4fm_ycs232_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_c4fm_ycs232_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_c4fm_ycs232_id_seq OWNED BY public.scrap_c4fm_ycs232.id;


--
-- Name: scrap_dmr_brandmeister_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dmr_brandmeister_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dmr_brandmeister_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dmr_brandmeister_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dmr_brandmeister_id_seq OWNED BY public.scrap_dmr_brandmeister.id;


--
-- Name: scrap_dmr_ipsc2_hotspot; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dmr_ipsc2_hotspot (
    id integer NOT NULL,
    nr text,
    callsign text,
    info text,
    repeater_id text,
    ts1 text,
    cq text,
    ts1_info text,
    ts2 text,
    ts2_info text,
    ref text,
    start text,
    hardware text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dmr_ipsc2_hotspot OWNER TO vhf_owner;

--
-- Name: scrap_dmr_ipsc2_hotspot_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dmr_ipsc2_hotspot_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dmr_ipsc2_hotspot_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dmr_ipsc2_hotspot_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dmr_ipsc2_hotspot_id_seq OWNED BY public.scrap_dmr_ipsc2_hotspot.id;


--
-- Name: scrap_dmr_ipsc2_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dmr_ipsc2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dmr_ipsc2_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dmr_ipsc2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dmr_ipsc2_id_seq OWNED BY public.scrap_dmr_ipsc2.id;


--
-- Name: scrap_dstar_dcs009_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dstar_dcs009_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dstar_dcs009_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dstar_dcs009_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dstar_dcs009_id_seq OWNED BY public.scrap_dstar_dcs009.id;


--
-- Name: scrap_dstar_ircddb_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dstar_ircddb_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dstar_ircddb_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dstar_ircddb_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dstar_ircddb_id_seq OWNED BY public.scrap_dstar_ircddb.id;


--
-- Name: scrap_dstar_ref; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_dstar_ref (
    id integer NOT NULL,
    callsign text,
    city text,
    state text,
    freq_2m text,
    freq_70cm text,
    freq_23cm text,
    freq_23cmdd text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_dstar_ref OWNER TO vhf_owner;

--
-- Name: scrap_dstar_ref096_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dstar_ref096_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dstar_ref096_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dstar_ref096_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dstar_ref096_id_seq OWNED BY public.scrap_dstar_ref096.id;


--
-- Name: scrap_dstar_ref_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dstar_ref_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dstar_ref_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dstar_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dstar_ref_id_seq OWNED BY public.scrap_dstar_ref.id;


--
-- Name: scrap_dstar_xlx905_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_dstar_xlx905_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_dstar_xlx905_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_dstar_xlx905_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_dstar_xlx905_id_seq OWNED BY public.scrap_dstar_xlx905.id;


--
-- Name: scrap_fm_svx_oe9_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_fm_svx_oe9_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_fm_svx_oe9_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_fm_svx_oe9_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_fm_svx_oe9_id_seq OWNED BY public.scrap_fm_svx_oe9.id;


--
-- Name: scrap_oelink_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_oelink_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_oelink_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_oelink_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_oelink_id_seq OWNED BY public.scrap_oelink.id;


--
-- Name: scrap_tetra_de_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_tetra_de_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_tetra_de_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_tetra_de_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_tetra_de_id_seq OWNED BY public.scrap_tetra_de.id;


--
-- Name: scrap_tetra_oevsv_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_tetra_oevsv_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_tetra_oevsv_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_tetra_oevsv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_tetra_oevsv_id_seq OWNED BY public.scrap_tetra_oevsv.id;


--
-- Name: scrap_winlink_pactor; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.scrap_winlink_pactor (
    id integer NOT NULL,
    posted text,
    callsign text,
    grid_square text,
    frequency text,
    mode text,
    hours text,
    qth text,
    scraped_timestamp timestamp without time zone NOT NULL
);


ALTER TABLE public.scrap_winlink_pactor OWNER TO vhf_owner;

--
-- Name: scrap_winlink_pactor_id_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.scrap_winlink_pactor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scrap_winlink_pactor_id_seq OWNER TO vhf_owner;

--
-- Name: scrap_winlink_pactor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.scrap_winlink_pactor_id_seq OWNED BY public.scrap_winlink_pactor.id;


--
-- Name: setting_options_uid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.setting_options_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.setting_options_uid_seq OWNER TO postgres;

--
-- Name: setting_options_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.setting_options_uid_seq OWNED BY public.setting_options.uid;


--
-- Name: site_callsigns_all; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_all AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.status)::text = 'active'::text)
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_all OWNER TO vhf_owner;

--
-- Name: site_callsigns_atv; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_atv AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'atv'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_atv OWNER TO vhf_owner;

--
-- Name: site_callsigns_beacon; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_beacon AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'beacon'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_beacon OWNER TO vhf_owner;

--
-- Name: site_callsigns_c4fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_c4fm AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.c4fm = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_c4fm OWNER TO vhf_owner;

--
-- Name: site_callsigns_digipeater; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_digipeater AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'digipeater'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_digipeater OWNER TO vhf_owner;

--
-- Name: site_callsigns_dmr; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_dmr AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.dmr = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_dmr OWNER TO vhf_owner;

--
-- Name: site_callsigns_dstar; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_dstar AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.dstar = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_dstar OWNER TO vhf_owner;

--
-- Name: site_callsigns_fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_fm AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx,
    string_agg(DISTINCT (trx.ctcss_rx)::text, '/'::text ORDER BY (trx.ctcss_rx)::text DESC) AS ctcss
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.fm = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_fm OWNER TO vhf_owner;

--
-- Name: site_callsigns_oe_link; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_oe_link AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx,
    string_agg(DISTINCT (trx.ctcss_rx)::text, '/'::text ORDER BY (trx.ctcss_rx)::text DESC) AS ctcss
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.fm = true) AND ((trx.status)::text = 'active'::text) AND ((trx.comment)::text = 'OE-Link'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_oe_link OWNER TO vhf_owner;

--
-- Name: site_callsigns_tetra; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_callsigns_tetra AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.vhf_nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.vhf_nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.tetra = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_tetra OWNER TO vhf_owner;

--
-- Name: site_list; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.site_list AS
 SELECT s.site_name AS "Site name",
    s.city AS "City",
    public.vhf_maidenhead_loc(s.longitude, s.latitude) AS "Loc short",
    public.vhf_maidenhead_loc(s.longitude, s.latitude, 6) AS "Loc long",
    public.vhf_nice_geo(s.longitude) AS "Longitude",
    public.vhf_nice_geo(s.latitude) AS "Latitude",
    to_char(s.longitude, '990.999999'::text) AS "Long dez",
    to_char(s.latitude, '990.999999'::text) AS "Lat dez",
    string_agg(DISTINCT (t.callsign)::text, ' '::text ORDER BY (t.callsign)::text) AS "Callsigns"
   FROM (public.site s
     LEFT JOIN public.trx t ON (((s.site_name)::text = (t.site_name)::text)))
  WHERE ((t.status)::text = 'active'::text)
  GROUP BY s.site_name, s.geom, s.city, s.geo_prefix, s.latitude, s.longitude
  ORDER BY s.site_name;


ALTER TABLE public.site_list OWNER TO vhf_owner;

--
-- Name: srv07_mapping; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.srv07_mapping (
    uid integer NOT NULL,
    callsign character varying(10) NOT NULL,
    frequency_tx double precision NOT NULL,
    frequency_srv07 double precision NOT NULL
);


ALTER TABLE public.srv07_mapping OWNER TO vhf_owner;

--
-- Name: COLUMN srv07_mapping.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.srv07_mapping.uid IS 'UID';


--
-- Name: COLUMN srv07_mapping.callsign; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.srv07_mapping.callsign IS 'Callsign of mapped station';


--
-- Name: COLUMN srv07_mapping.frequency_tx; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.srv07_mapping.frequency_tx IS 'Frequency according to repeater table (correct frequency)';


--
-- Name: COLUMN srv07_mapping.frequency_srv07; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.srv07_mapping.frequency_srv07 IS 'Frequency according to src07 (IPSC2)';


--
-- Name: srv07_mapping_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.srv07_mapping_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.srv07_mapping_uid_seq OWNER TO vhf_owner;

--
-- Name: srv07_mapping_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.srv07_mapping_uid_seq OWNED BY public.srv07_mapping.uid;


--
-- Name: srv07_status; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.srv07_status (
    uid integer NOT NULL,
    protocol character varying(5),
    digital_id bigint,
    callsign character varying(8),
    default_group integer,
    qual integer,
    frequency_tx double precision,
    frequency_offset double precision,
    registered integer,
    extra_col character varying(50)
);


ALTER TABLE public.srv07_status OWNER TO vhf_owner;

--
-- Name: COLUMN srv07_status.uid; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.srv07_status.uid IS 'UID';


--
-- Name: srv07_status_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.srv07_status_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.srv07_status_uid_seq OWNER TO vhf_owner;

--
-- Name: srv07_status_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.srv07_status_uid_seq OWNED BY public.srv07_status.uid;


--
-- Name: station_uid_seq; Type: SEQUENCE; Schema: public; Owner: vhf_owner
--

CREATE SEQUENCE public.station_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_uid_seq OWNER TO vhf_owner;

--
-- Name: station_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vhf_owner
--

ALTER SEQUENCE public.station_uid_seq OWNED BY public.site.uid;


--
-- Name: ticket_config; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.ticket_config (
    id boolean DEFAULT true NOT NULL,
    staff_only boolean DEFAULT true NOT NULL,
    CONSTRAINT ticket_config_one_row CHECK (id)
);


ALTER TABLE public.ticket_config OWNER TO vhf_owner;

--
-- Name: TABLE ticket_config; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.ticket_config IS 'Ticket settings (one row)';


--
-- Name: COLUMN ticket_config.staff_only; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket_config.staff_only IS 'true: tickets only for staff (users.staff4), hidden for everyone else';


--
-- Name: ticket_message; Type: TABLE; Schema: public; Owner: vhf_owner
--

CREATE TABLE public.ticket_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    user_id uuid NOT NULL,
    staff boolean DEFAULT false NOT NULL,
    body text NOT NULL,
    created timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    mailed timestamp with time zone,
    CONSTRAINT ticket_message_body_check CHECK (((btrim(body) <> ''::text) AND (length(body) <= 20000)))
);


ALTER TABLE public.ticket_message OWNER TO vhf_owner;

--
-- Name: TABLE ticket_message; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON TABLE public.ticket_message IS 'Messages of a ticket: the submitted text and the replies';


--
-- Name: COLUMN ticket_message.staff; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket_message.staff IS 'Written by staff (users.staff4 at that time)';


--
-- Name: COLUMN ticket_message.created; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket_message.created IS 'clock_timestamp(): keeps the order of messages written in one transaction';


--
-- Name: COLUMN ticket_message.mailed; Type: COMMENT; Schema: public; Owner: vhf_owner
--

COMMENT ON COLUMN public.ticket_message.mailed IS 'E-mail notification sent (scripts/ticket_mail.py); NULL: not yet';


--
-- Name: trx_list_atv; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_atv AS
 SELECT COALESCE(t.band, public.vhf_band_name(t.frequency_rx)) AS "Band",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.other_mode_name AS "Mode",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'atv'::text);


ALTER TABLE public.trx_list_atv OWNER TO vhf_owner;

--
-- Name: trx_list_beacon; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_beacon AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    t.sysop AS "Sysop",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.locator_long AS "Locator",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'beacon'::text);


ALTER TABLE public.trx_list_beacon OWNER TO vhf_owner;

--
-- Name: trx_list_c4fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_c4fm AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ','::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.c4fm_groups IS NOT NULL) THEN (t.c4fm_groups)::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.c4fm = true);


ALTER TABLE public.trx_list_c4fm OWNER TO vhf_owner;

--
-- Name: trx_list_digipeater; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_digipeater AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.other_mode_name AS "Mode",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'digipeater'::text);


ALTER TABLE public.trx_list_digipeater OWNER TO vhf_owner;

--
-- Name: trx_list_dmr; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_dmr AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.digital_id AS "Digital ID",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN ((t.cc IS NOT NULL) AND (t.cc <> 1)) THEN concat('CC=', t.cc, ' ')
            ELSE NULL::text
        END,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ','::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.ipsc2 = true) THEN 'IPSC2 '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.brandmeister = true) THEN 'BM '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.dmr = true);


ALTER TABLE public.trx_list_dmr OWNER TO vhf_owner;

--
-- Name: trx_list_dstar; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_dstar AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ' '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.dstar = true);


ALTER TABLE public.trx_list_dstar OWNER TO vhf_owner;

--
-- Name: trx_list_fm; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_fm AS
 SELECT t.band AS "Band",
    t.label AS "Label",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frequency RX",
    t.ch AS "Ch",
    t.ctcss_tx AS "CTCSS TX",
    t.ctcss_rx AS "CTCSS RX",
    t.fm_wakeup AS "Wakeup",
    t.sysop AS "Sysop",
    t.echolink_id AS "Echolink",
    t.comment AS "Comment",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel"
   FROM public.trx_list t
  WHERE (t.fm = true);


ALTER TABLE public.trx_list_fm OWNER TO vhf_owner;

--
-- Name: trx_list_fm_oe_link; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_fm_oe_link AS
 SELECT t.band AS "Band",
    t.label AS "Label",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frequency RX",
    t.ch AS "Ch",
    t.ctcss_tx AS "CTCSS TX",
    t.ctcss_rx AS "CTCSS RX",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel"
   FROM public.trx_list t
  WHERE ((t.fm = true) AND ((t.comment)::text = 'OE-Link'::text));


ALTER TABLE public.trx_list_fm_oe_link OWNER TO vhf_owner;

--
-- Name: trx_list_fm_qsp; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_fm_qsp AS
 SELECT t.band AS "Band",
    t.label AS "Label",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frequency RX",
    t.ch AS "Ch",
    t.ctcss_tx AS "CTCSS TX",
    t.ctcss_rx AS "CTCSS RX",
    t.fm_wakeup AS "Wakeup",
    t.sysop AS "Sysop",
    t.echolink_id AS "Echolink",
    t.comment AS "Comment",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel"
   FROM public.trx_list t
  WHERE (t.fm = true);


ALTER TABLE public.trx_list_fm_qsp OWNER TO vhf_owner;

--
-- Name: trx_list_tetra; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_list_tetra AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.site_name AS "Site",
    t.city AS "City",
    public.vhf_nice_frq(t.frequency_tx) AS "Frequency TX",
    public.vhf_nice_frq(t.frequency_rx) AS "Frquency RX",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    t.locator_short AS "Locator",
    public.vhf_nice_geo(t.longitude) AS "Longitude",
    public.vhf_nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE (t.tetra = true);


ALTER TABLE public.trx_list_tetra OWNER TO vhf_owner;

--
-- Name: trx_verylong; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.trx_verylong AS
 SELECT public.vhf_band_name(t.frequency_tx) AS band,
    public.vhf_channel_name(t.frequency_tx, t.frequency_rx, 0) AS ch,
    public.vhf_channel_name(t.frequency_tx, t.frequency_rx, 1) AS ch_new,
    t.uid,
    t.type_of_station,
    t.frequency_tx,
    t.frequency_rx,
    t.callsign,
    t.antenna_heigth,
    t.site_name,
    t.sysop,
    t.url,
    t.hardware,
    t.mmdvm,
    t.solar_power,
    t.battery_power,
    t.status,
    t.fm,
    t.fm_wakeup,
    t.ctcss_tx,
    t.ctcss_rx,
    t.echolink,
    t.echolink_id,
    t.digital_id,
    t.dmr,
    t.cc,
    t.ipsc2,
    t.brandmeister,
    t.network_registered,
    t.c4fm,
    t.c4fm_groups,
    t.dstar,
    t.dstar_rpt1,
    NULL::character varying(1) AS dstar_rpt2,
    t.tetra,
    t.other_mode,
    t.other_mode_name,
    t.comment,
    t.created_at,
    s.city,
    s.longitude,
    s.latitude,
    s.sea_level,
    s.locator_short,
    s.locator_long,
    s.geo_prefix,
    s.bev_gid,
    s.geom,
    l.name_address,
    o.gkz,
    o.bkz,
    o.kg,
    o.pg,
    o.bl
   FROM (((public.trx t
     LEFT JOIN public.site s ON (((s.site_name)::text = (t.site_name)::text)))
     LEFT JOIN public.licenses l ON (((t.callsign)::text = (l.callsign)::text)))
     LEFT JOIN public.oesterreich_bev_vgd_lam o ON ((o.gid = s.bev_gid)));


ALTER TABLE public.trx_verylong OWNER TO vhf_owner;

--
-- Name: yaesu_ft3; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.yaesu_ft3 AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel No",
    foobar."Priority CH",
    foobar."Receive Frequency",
    foobar."Transmit Frequency",
    foobar."Offset Frequency",
    foobar."Offset Direction",
    foobar."AUTO MODE",
    foobar."Operating Mode",
    foobar."DIG/ANALOG",
    foobar."TAG",
    foobar."Name",
    foobar."Tone Mode",
    foobar."CSCSS Frequency",
    foobar."DCS Code",
    foobar."DCS Polarity",
    foobar."User CTCSS",
    foobar."RX DG-ID",
    foobar."TX DG-ID",
    foobar."Tx Power",
    foobar."Skip",
    foobar."AUTO STEP",
    foobar."Step",
    foobar."Memory Mask",
    foobar."ATT",
    foobar."S-Meter SQL",
    foobar."Bell",
    foobar."Narrow",
    foobar."Clock Shift",
    foobar."BANK1",
    foobar."BANK2",
    foobar."BANK3",
    foobar."BANK4",
    foobar."BANK5",
    foobar."BANK6",
    foobar."BANK7",
    foobar."BANK8",
    foobar."BANK9",
    foobar."BANK10",
    foobar."BANK11",
    foobar."BANK12",
    foobar."BANK13",
    foobar."BANK14",
    foobar."BANK15",
    foobar."BANK16",
    foobar."BANK17",
    foobar."BANK18",
    foobar."BANK19",
    foobar."BANK20",
    foobar."BANK21",
    foobar."BANK22",
    foobar."BANK23",
    foobar."BANK24",
    foobar."Comment",
    foobar."Dummy"
   FROM (( SELECT 'OFF'::text AS "Priority CH",
            t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            (0)::double precision AS "Offset Frequency",
            '-/+'::text AS "Offset Direction",
            'ON'::text AS "AUTO MODE",
            'FM'::text AS "Operating Mode",
            'FM'::text AS "DIG/ANALOG",
            'ON'::text AS "TAG",
            "substring"((t.site_name)::text, 1, 16) AS "Name",
                CASE
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Tone'::text) THEN 'TONE'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'TSQL'::text) THEN 'TONE SQL'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Cross'::text) THEN 'TONE'::text
                    ELSE 'OFF'::text
                END AS "Tone Mode",
            btrim(concat(to_char(public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx), '999.9'::text), ' Hz')) AS "CSCSS Frequency",
            '023'::text AS "DCS Code",
            'RX Normal TX Normal'::text AS "DCS Polarity",
            '1700 Hz'::text AS "User CTCSS",
            'RX 00'::text AS "RX DG-ID",
            'TX 00'::text AS "TX DG-ID",
            'High (5W)'::text AS "Tx Power",
            'OFF'::text AS "Skip",
            'ON'::text AS "AUTO STEP",
            '12.5KHz'::text AS "Step",
            'OFF'::text AS "Memory Mask",
            'OFF'::text AS "ATT",
            'OFF'::text AS "S-Meter SQL",
            'OFF'::text AS "Bell",
            'OFF'::text AS "Narrow",
            'OFF'::text AS "Clock Shift",
            'OFF'::text AS "BANK1",
            'OFF'::text AS "BANK2",
            'OFF'::text AS "BANK3",
            'OFF'::text AS "BANK4",
            'OFF'::text AS "BANK5",
            'OFF'::text AS "BANK6",
            'OFF'::text AS "BANK7",
            'OFF'::text AS "BANK8",
            'OFF'::text AS "BANK9",
            'ON'::text AS "BANK10",
            'OFF'::text AS "BANK11",
            'OFF'::text AS "BANK12",
            'OFF'::text AS "BANK13",
            'OFF'::text AS "BANK14",
            'OFF'::text AS "BANK15",
            'OFF'::text AS "BANK16",
            'OFF'::text AS "BANK17",
            'OFF'::text AS "BANK18",
            'OFF'::text AS "BANK19",
            'OFF'::text AS "BANK20",
            'OFF'::text AS "BANK21",
            'OFF'::text AS "BANK22",
            'OFF'::text AS "BANK23",
            'OFF'::text AS "BANK24",
            (public.vhf_nice_display(t.site_name))::text AS "Comment",
            '0'::text AS "Dummy"
           FROM public.direct_channels t
          WHERE (((t.type_of_station)::text = 'direct'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND public.vhf_band_common(t.frequency_tx))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT 'OFF'::text AS "Priority CH",
            t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            (0)::double precision AS "Offset Frequency",
            '-/+'::text AS "Offset Direction",
            'ON'::text AS "AUTO MODE",
            'FM'::text AS "Operating Mode",
            'FM'::text AS "DIG/ANALOG",
            'ON'::text AS "TAG",
            "substring"(concat(t.callsign, '-', "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1), ' ', public.vhf_nice_display(t.site_name)), 1, 16) AS "Name",
                CASE
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Tone'::text) THEN 'TONE'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'TSQL'::text) THEN 'TONE SQL'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Cross'::text) THEN 'TONE'::text
                    ELSE 'OFF'::text
                END AS "Tone Mode",
            btrim(concat(to_char(public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx), '999.9'::text), ' Hz')) AS "CSCSS Frequency",
            '023'::text AS "DCS Code",
            'RX Normal TX Normal'::text AS "DCS Polarity",
            '1500 Hz'::text AS "User CTCSS",
            'RX 00'::text AS "RX DG-ID",
            'TX 00'::text AS "TX DG-ID",
            'High (5W)'::text AS "Tx Power",
            'OFF'::text AS "Skip",
            'ON'::text AS "AUTO STEP",
            '12.5KHz'::text AS "Step",
            'OFF'::text AS "Memory Mask",
            'OFF'::text AS "ATT",
            'OFF'::text AS "S-Meter SQL",
            'OFF'::text AS "Bell",
            'OFF'::text AS "Narrow",
            'OFF'::text AS "Clock Shift",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '1'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK1",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '2'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK2",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '3'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK3",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '4'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK4",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '5'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK5",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '6'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK6",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '7'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK7",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '8'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK8",
                CASE
                    WHEN ("substring"((t.callsign)::text, 3, 1) = '9'::text) THEN 'ON'::text
                    ELSE 'OFF'::text
                END AS "BANK9",
            'OFF'::text AS "BANK10",
            'OFF'::text AS "BANK11",
            'OFF'::text AS "BANK12",
            'OFF'::text AS "BANK13",
            'OFF'::text AS "BANK14",
            'OFF'::text AS "BANK15",
            'OFF'::text AS "BANK16",
            'OFF'::text AS "BANK17",
            'OFF'::text AS "BANK18",
            'OFF'::text AS "BANK19",
            'OFF'::text AS "BANK20",
            'OFF'::text AS "BANK21",
            'OFF'::text AS "BANK22",
            'OFF'::text AS "BANK23",
            'OFF'::text AS "BANK24",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx)) AS "Comment",
            '0'::text AS "Dummy"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND public.vhf_band_common(t.frequency_tx))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar;


ALTER TABLE public.yaesu_ft3 OWNER TO vhf_owner;

--
-- Name: yaesu_ftm400; Type: VIEW; Schema: public; Owner: vhf_owner
--

CREATE VIEW public.yaesu_ftm400 AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel No",
    foobar."Receive Frequency",
    foobar."Transmit Frequency",
    foobar."Offset Frequency",
    foobar."Offset Direction",
    foobar."Operating Mode",
    foobar."Name",
    foobar."Tone Mode",
    foobar."CSCSS Frequency",
    foobar."DCS Code",
    foobar."User CTCSS",
    foobar."Tx Power",
    foobar."Skip",
    foobar."Step",
    foobar."Clock Shift",
    foobar."Comment",
    foobar."Dummy"
   FROM (( SELECT t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            (0)::double precision AS "Offset Frequency",
            '-/+'::text AS "Offset Direction",
            'FM'::text AS "Operating Mode",
            "substring"((t.site_name)::text, 1, 6) AS "Name",
                CASE
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Tone'::text) THEN 'TONE ENC'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'TSQL'::text) THEN 'TONE SQL'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Cross'::text) THEN 'TONE ENC'::text
                    ELSE 'OFF'::text
                END AS "Tone Mode",
            btrim(concat(to_char(public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx), '999.9'::text), ' Hz')) AS "CSCSS Frequency",
            '023'::text AS "DCS Code",
            '1500 Hz'::text AS "User CTCSS",
            'HIGH'::text AS "Tx Power",
            'SELECT'::text AS "Skip",
            '12.5KHz'::text AS "Step",
            '0'::text AS "Clock Shift",
            (public.vhf_nice_display(t.site_name))::text AS "Comment",
            '0'::text AS "Dummy"
           FROM public.direct_channels t
          WHERE (((t.type_of_station)::text = 'direct'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND public.vhf_band_common(t.frequency_tx))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))
        UNION ALL
        ( SELECT t.frequency_tx AS "Receive Frequency",
            t.frequency_rx AS "Transmit Frequency",
            (0)::double precision AS "Offset Frequency",
            '-/+'::text AS "Offset Direction",
            'FM'::text AS "Operating Mode",
            "substring"(concat(t.callsign,
                CASE
                    WHEN ((t.fm = true) AND (t.c4fm IS NULL)) THEN '-'::text
                    WHEN ((t.fm = true) AND (t.c4fm = true)) THEN '*'::text
                    ELSE 'c'::text
                END, "substring"((public.vhf_band_name(t.frequency_tx))::text, 1, 1)), 1, 8) AS "Name",
                CASE
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Tone'::text) THEN 'TONE ENC'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'TSQL'::text) THEN 'TONE SQL'::text
                    WHEN ((public."vhf_chirp_Tone"(t.ctcss_tx, t.ctcss_rx))::text = 'Cross'::text) THEN 'TONE ENC'::text
                    ELSE 'OFF'::text
                END AS "Tone Mode",
            btrim(concat(to_char(public.vhf_chirp_rtonefreq(t.ctcss_tx, t.ctcss_rx), '999.9'::text), ' Hz')) AS "CSCSS Frequency",
            '023'::text AS "DCS Code",
            '1700 Hz'::text AS "User CTCSS",
            'HIGH'::text AS "Tx Power",
            'SELECT'::text AS "Skip",
            '12.5KHz'::text AS "Step",
            '0'::text AS "Clock Shift",
            concat(public.vhf_nice_display(t.site_name), ' ', public.vhf_band_name(t.frequency_tx), ' ',
                CASE
                    WHEN ((t.fm = true) AND (t.c4fm IS NULL)) THEN '(FM only)'::text
                    WHEN ((t.fm = true) AND (t.c4fm = true)) THEN '(FM or C4FM)'::text
                    ELSE '(C4FM only)'::text
                END) AS "Comment",
            '0'::text AS "Dummy"
           FROM public.trx t
          WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND ((t.fm = true) OR (t.c4fm = true)) AND ((t.status)::text = 'active'::text) AND public.vhf_band_common(t.frequency_tx))
          ORDER BY (public.vhf_band_common(t.frequency_tx)), t.callsign, (public.vhf_band_name(t.frequency_tx)))) foobar;


ALTER TABLE public.yaesu_ftm400 OWNER TO vhf_owner;

--
-- Name: bands uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.bands ALTER COLUMN uid SET DEFAULT nextval('public.band_uid_seq'::regclass);


--
-- Name: beacon_import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.beacon_import ALTER COLUMN uid SET DEFAULT nextval('public.beacon_import_uid_seq'::regclass);


--
-- Name: bl_kz_prefix uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.bl_kz_prefix ALTER COLUMN uid SET DEFAULT nextval('public.bl_kz_prefix_uid_seq'::regclass);


--
-- Name: dhm rid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dhm ALTER COLUMN rid SET DEFAULT nextval('public.dhm_rid_seq'::regclass);


--
-- Name: digital_repeater_id_import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.digital_repeater_id_import ALTER COLUMN uid SET DEFAULT nextval('public.digital_repeater_id_import_uid_seq'::regclass);


--
-- Name: dmr_groups uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.dmr_groups ALTER COLUMN uid SET DEFAULT nextval('public."dmr-groups_uid_seq"'::regclass);


--
-- Name: dstar-oevsv-import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public."dstar-oevsv-import" ALTER COLUMN uid SET DEFAULT nextval('public."dstar-oevsv-import_uid_seq"'::regclass);


--
-- Name: dstar_at_import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.dstar_at_import ALTER COLUMN uid SET DEFAULT nextval('public."dstar-import_uid_seq"'::regclass);


--
-- Name: echolink-import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public."echolink-import" ALTER COLUMN uid SET DEFAULT nextval('public.echolink_uid_seq'::regclass);


--
-- Name: import_hamnet_site uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.import_hamnet_site ALTER COLUMN uid SET DEFAULT nextval('public.import_hamnet_site_uid_seq'::regclass);


--
-- Name: licenses uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.licenses ALTER COLUMN uid SET DEFAULT nextval('public.licenses_uid_seq'::regclass);


--
-- Name: oesterreich_bev_vgd_lam gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oesterreich_bev_vgd_lam ALTER COLUMN gid SET DEFAULT nextval('public.oesterreich_bev_vgd_lam_gid_seq'::regclass);


--
-- Name: packet_import uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.packet_import ALTER COLUMN uid SET DEFAULT nextval('public.packet_import_uid_seq'::regclass);


--
-- Name: scrap_c4fm_ycs232 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_c4fm_ycs232 ALTER COLUMN id SET DEFAULT nextval('public.scrap_c4fm_ycs232_id_seq'::regclass);


--
-- Name: scrap_dmr_brandmeister id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_brandmeister ALTER COLUMN id SET DEFAULT nextval('public.scrap_dmr_brandmeister_id_seq'::regclass);


--
-- Name: scrap_dmr_ipsc2 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_ipsc2 ALTER COLUMN id SET DEFAULT nextval('public.scrap_dmr_ipsc2_id_seq'::regclass);


--
-- Name: scrap_dmr_ipsc2_hotspot id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_ipsc2_hotspot ALTER COLUMN id SET DEFAULT nextval('public.scrap_dmr_ipsc2_hotspot_id_seq'::regclass);


--
-- Name: scrap_dstar_dcs009 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_dcs009 ALTER COLUMN id SET DEFAULT nextval('public.scrap_dstar_dcs009_id_seq'::regclass);


--
-- Name: scrap_dstar_ircddb id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ircddb ALTER COLUMN id SET DEFAULT nextval('public.scrap_dstar_ircddb_id_seq'::regclass);


--
-- Name: scrap_dstar_ref id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ref ALTER COLUMN id SET DEFAULT nextval('public.scrap_dstar_ref_id_seq'::regclass);


--
-- Name: scrap_dstar_ref096 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ref096 ALTER COLUMN id SET DEFAULT nextval('public.scrap_dstar_ref096_id_seq'::regclass);


--
-- Name: scrap_dstar_xlx905 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_xlx905 ALTER COLUMN id SET DEFAULT nextval('public.scrap_dstar_xlx905_id_seq'::regclass);


--
-- Name: scrap_fm_svx_oe9 id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_fm_svx_oe9 ALTER COLUMN id SET DEFAULT nextval('public.scrap_fm_svx_oe9_id_seq'::regclass);


--
-- Name: scrap_oelink id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_oelink ALTER COLUMN id SET DEFAULT nextval('public.scrap_oelink_id_seq'::regclass);


--
-- Name: scrap_tetra_de id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_tetra_de ALTER COLUMN id SET DEFAULT nextval('public.scrap_tetra_de_id_seq'::regclass);


--
-- Name: scrap_tetra_oevsv id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_tetra_oevsv ALTER COLUMN id SET DEFAULT nextval('public.scrap_tetra_oevsv_id_seq'::regclass);


--
-- Name: scrap_winlink_pactor id; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_winlink_pactor ALTER COLUMN id SET DEFAULT nextval('public.scrap_winlink_pactor_id_seq'::regclass);


--
-- Name: setting_options uid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.setting_options ALTER COLUMN uid SET DEFAULT nextval('public.setting_options_uid_seq'::regclass);


--
-- Name: site uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.site ALTER COLUMN uid SET DEFAULT nextval('public.station_uid_seq'::regclass);


--
-- Name: srv07_mapping uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.srv07_mapping ALTER COLUMN uid SET DEFAULT nextval('public.srv07_mapping_uid_seq'::regclass);


--
-- Name: srv07_status uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.srv07_status ALTER COLUMN uid SET DEFAULT nextval('public.srv07_status_uid_seq'::regclass);


--
-- Name: trx uid; Type: DEFAULT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.trx ALTER COLUMN uid SET DEFAULT nextval('public.repeater_uid_seq'::regclass);


--
-- Name: dhm dhm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dhm
    ADD CONSTRAINT dhm_pkey PRIMARY KEY (rid);


--
-- Name: network network_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_pkey PRIMARY KEY (id);


--
-- Name: oesterreich_bev_vgd_lam oesterreich_bev_vgd_lam_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oesterreich_bev_vgd_lam
    ADD CONSTRAINT oesterreich_bev_vgd_lam_pkey PRIMARY KEY (gid);


--
-- Name: import_hamnet_site pk_import_hamnet_site; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.import_hamnet_site
    ADD CONSTRAINT pk_import_hamnet_site PRIMARY KEY (uid);


--
-- Name: site pk_site; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.site
    ADD CONSTRAINT pk_site PRIMARY KEY (uid);


--
-- Name: scrap_c4fm_ycs232 scrap_c4fm_ycs232_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_c4fm_ycs232
    ADD CONSTRAINT scrap_c4fm_ycs232_pkey PRIMARY KEY (id);


--
-- Name: scrap_dmr_brandmeister scrap_dmr_brandmeister_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_brandmeister
    ADD CONSTRAINT scrap_dmr_brandmeister_pkey PRIMARY KEY (id);


--
-- Name: scrap_dmr_ipsc2_hotspot scrap_dmr_ipsc2_hotspot_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_ipsc2_hotspot
    ADD CONSTRAINT scrap_dmr_ipsc2_hotspot_pkey PRIMARY KEY (id);


--
-- Name: scrap_dmr_ipsc2 scrap_dmr_ipsc2_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dmr_ipsc2
    ADD CONSTRAINT scrap_dmr_ipsc2_pkey PRIMARY KEY (id);


--
-- Name: scrap_dstar_dcs009 scrap_dstar_dcs009_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_dcs009
    ADD CONSTRAINT scrap_dstar_dcs009_pkey PRIMARY KEY (id);


--
-- Name: scrap_dstar_ircddb scrap_dstar_ircddb_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ircddb
    ADD CONSTRAINT scrap_dstar_ircddb_pkey PRIMARY KEY (id);


--
-- Name: scrap_dstar_ref096 scrap_dstar_ref096_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ref096
    ADD CONSTRAINT scrap_dstar_ref096_pkey PRIMARY KEY (id);


--
-- Name: scrap_dstar_ref scrap_dstar_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_ref
    ADD CONSTRAINT scrap_dstar_ref_pkey PRIMARY KEY (id);


--
-- Name: scrap_dstar_xlx905 scrap_dstar_xlx905_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_dstar_xlx905
    ADD CONSTRAINT scrap_dstar_xlx905_pkey PRIMARY KEY (id);


--
-- Name: scrap_fm_svx_oe9 scrap_fm_svx_oe9_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_fm_svx_oe9
    ADD CONSTRAINT scrap_fm_svx_oe9_pkey PRIMARY KEY (id);


--
-- Name: scrap_oelink scrap_oelink_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_oelink
    ADD CONSTRAINT scrap_oelink_pkey PRIMARY KEY (id);


--
-- Name: scrap_tetra_de scrap_tetra_de_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_tetra_de
    ADD CONSTRAINT scrap_tetra_de_pkey PRIMARY KEY (id);


--
-- Name: scrap_tetra_oevsv scrap_tetra_oevsv_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_tetra_oevsv
    ADD CONSTRAINT scrap_tetra_oevsv_pkey PRIMARY KEY (id);


--
-- Name: scrap_winlink_pactor scrap_winlink_pactor_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.scrap_winlink_pactor
    ADD CONSTRAINT scrap_winlink_pactor_pkey PRIMARY KEY (id);


--
-- Name: ticket_config ticket_config_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket_config
    ADD CONSTRAINT ticket_config_pkey PRIMARY KEY (id);


--
-- Name: ticket_message ticket_message_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket_message
    ADD CONSTRAINT ticket_message_pkey PRIMARY KEY (id);


--
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- Name: trx trx_pk; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.trx
    ADD CONSTRAINT trx_pk PRIMARY KEY (uid);


--
-- Name: direct_channels trx_pk_1; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.direct_channels
    ADD CONSTRAINT trx_pk_1 PRIMARY KEY (uid);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: band_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX band_uid_idx ON public.bands USING btree (uid);


--
-- Name: beacon_import_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX beacon_import_uid_idx ON public.beacon_import USING btree (uid);


--
-- Name: dhm_st_convexhull_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dhm_st_convexhull_idx ON public.dhm USING gist (public.st_convexhull(rast));


--
-- Name: digital_repeater_id_import_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX digital_repeater_id_import_uid_idx ON public.digital_repeater_id_import USING btree (uid);


--
-- Name: dmr_groups_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX dmr_groups_uid_idx ON public.dmr_groups USING btree (uid);


--
-- Name: dstar_import_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX dstar_import_uid_idx ON public.dstar_at_import USING btree (uid);


--
-- Name: dstar_oevsv_import_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX dstar_oevsv_import_uid_idx ON public."dstar-oevsv-import" USING btree (uid);


--
-- Name: echolink_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX echolink_uid_idx ON public."echolink-import" USING btree (uid);


--
-- Name: import_hamnet_site_geom_gix; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX import_hamnet_site_geom_gix ON public.import_hamnet_site USING gist (geom);


--
-- Name: licenses_callsign_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX licenses_callsign_idx ON public.licenses USING btree (callsign);


--
-- Name: licenses_suffix_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX licenses_suffix_idx ON public.licenses USING btree (suffix);


--
-- Name: licenses_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX licenses_uid_idx ON public.licenses USING btree (uid);


--
-- Name: oesterreich_bev_vgd_lam_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX oesterreich_bev_vgd_lam_geom_idx ON public.oesterreich_bev_vgd_lam USING gist (geom);


--
-- Name: scrap_c4fm_ycs232_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_c4fm_ycs232_callsign_ts_idx ON public.scrap_c4fm_ycs232 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dmr_brandmeister_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dmr_brandmeister_callsign_ts_idx ON public.scrap_dmr_brandmeister USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dmr_brandmeister_device_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dmr_brandmeister_device_ts_idx ON public.scrap_dmr_brandmeister USING btree (device_id, scraped_timestamp DESC) INCLUDE (callsign, hardware, last_seen);


--
-- Name: scrap_dmr_ipsc2_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dmr_ipsc2_callsign_ts_idx ON public.scrap_dmr_ipsc2 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dstar_dcs009_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dstar_dcs009_callsign_ts_idx ON public.scrap_dstar_dcs009 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dstar_ircddb_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dstar_ircddb_callsign_ts_idx ON public.scrap_dstar_ircddb USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dstar_ref096_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dstar_ref096_callsign_ts_idx ON public.scrap_dstar_ref096 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_dstar_xlx905_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_dstar_xlx905_callsign_ts_idx ON public.scrap_dstar_xlx905 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_fm_svx_oe9_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_fm_svx_oe9_callsign_ts_idx ON public.scrap_fm_svx_oe9 USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_oelink_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_oelink_callsign_ts_idx ON public.scrap_oelink USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_tetra_de_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_tetra_de_callsign_ts_idx ON public.scrap_tetra_de USING btree (callsign, scraped_timestamp DESC);


--
-- Name: scrap_tetra_oevsv_callsign_ts_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX scrap_tetra_oevsv_callsign_ts_idx ON public.scrap_tetra_oevsv USING btree (callsign, scraped_timestamp DESC);


--
-- Name: site_geom_gix; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX site_geom_gix ON public.site USING gist (geom);


--
-- Name: site_name_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE UNIQUE INDEX site_name_idx ON public.site USING btree (site_name);


--
-- Name: srv07_mapping_uid_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX srv07_mapping_uid_idx ON public.srv07_mapping USING btree (uid);


--
-- Name: ticket_message_ticket_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX ticket_message_ticket_idx ON public.ticket_message USING btree (ticket_id, created);


--
-- Name: ticket_message_unmailed_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX ticket_message_unmailed_idx ON public.ticket_message USING btree (created) WHERE (mailed IS NULL);


--
-- Name: ticket_updated_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX ticket_updated_idx ON public.ticket USING btree (updated DESC);


--
-- Name: ticket_user_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX ticket_user_idx ON public.ticket USING btree (user_id, updated DESC);


--
-- Name: trx_c4fm_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_c4fm_idx ON public.trx USING btree (c4fm);


--
-- Name: trx_c4fm_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_c4fm_idx_1 ON public.direct_channels USING btree (c4fm);


--
-- Name: trx_callsign_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_callsign_idx ON public.trx USING btree (callsign);


--
-- Name: trx_callsign_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_callsign_idx_1 ON public.direct_channels USING btree (callsign);


--
-- Name: trx_dmr_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_dmr_idx ON public.trx USING btree (dmr);


--
-- Name: trx_dmr_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_dmr_idx_1 ON public.direct_channels USING btree (dmr);


--
-- Name: trx_dstar_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_dstar_idx ON public.trx USING btree (dstar);


--
-- Name: trx_dstar_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_dstar_idx_1 ON public.direct_channels USING btree (dstar);


--
-- Name: trx_fm_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_fm_idx ON public.trx USING btree (fm);


--
-- Name: trx_fm_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_fm_idx_1 ON public.direct_channels USING btree (fm);


--
-- Name: trx_frequency_tx_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_frequency_tx_idx ON public.trx USING btree (frequency_tx);


--
-- Name: trx_frequency_tx_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_frequency_tx_idx_1 ON public.direct_channels USING btree (frequency_tx);


--
-- Name: trx_networks_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_networks_idx ON public.trx USING gin (networks jsonb_path_ops);


--
-- Name: trx_other_mode_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_other_mode_idx ON public.trx USING btree (other_mode);


--
-- Name: trx_other_mode_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_other_mode_idx_1 ON public.direct_channels USING btree (other_mode);


--
-- Name: trx_site_name_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_site_name_idx ON public.trx USING btree (site_name);


--
-- Name: trx_site_name_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_site_name_idx_1 ON public.direct_channels USING btree (site_name);


--
-- Name: trx_tetra_idx; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_tetra_idx ON public.trx USING btree (tetra);


--
-- Name: trx_tetra_idx_1; Type: INDEX; Schema: public; Owner: vhf_owner
--

CREATE INDEX trx_tetra_idx_1 ON public.direct_channels USING btree (tetra);


--
-- Name: import_hamnet_site import_hamnet_site_trigger; Type: TRIGGER; Schema: public; Owner: vhf_owner
--

CREATE TRIGGER import_hamnet_site_trigger BEFORE INSERT OR UPDATE ON public.import_hamnet_site FOR EACH ROW EXECUTE FUNCTION public.vhf_trigger_import_hamnet_site();


--
-- Name: site site_trigger; Type: TRIGGER; Schema: public; Owner: vhf_owner
--

CREATE TRIGGER site_trigger BEFORE INSERT OR UPDATE ON public.site FOR EACH ROW EXECUTE FUNCTION public.vhf_trigger_site();


--
-- Name: ticket_message ticket_message_mail; Type: TRIGGER; Schema: public; Owner: vhf_owner
--

CREATE TRIGGER ticket_message_mail AFTER INSERT ON public.ticket_message FOR EACH ROW EXECUTE FUNCTION public.ticket_message_mail();


--
-- Name: trx trx_networks_check; Type: TRIGGER; Schema: public; Owner: vhf_owner
--

CREATE TRIGGER trx_networks_check BEFORE INSERT OR UPDATE OF networks ON public.trx FOR EACH ROW EXECUTE FUNCTION public.trx_networks_check();


--
-- Name: ticket_message ticket_message_ticket_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket_message
    ADD CONSTRAINT ticket_message_ticket_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE;


--
-- Name: ticket_message ticket_message_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket_message
    ADD CONSTRAINT ticket_message_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ticket ticket_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trx trx_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: vhf_owner
--

ALTER TABLE ONLY public.trx
    ADD CONSTRAINT trx_site_fk FOREIGN KEY (site_name) REFERENCES public.site(site_name) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SCHEMA api; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA api TO web_anon;
GRANT ALL ON SCHEMA api TO dz;
GRANT USAGE ON SCHEMA api TO web_user;
GRANT ALL ON SCHEMA api TO vhf_owner;
GRANT USAGE ON SCHEMA api TO vhf_ticket_writer;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO vhf_owner;
GRANT USAGE ON SCHEMA public TO vhf_login_writer;
GRANT USAGE ON SCHEMA public TO vhf_ticket_writer;
GRANT USAGE ON SCHEMA public TO repeater_mail;


--
-- Name: FUNCTION geo(x double precision, y double precision); Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT ALL ON FUNCTION api.geo(x double precision, y double precision) TO web_anon;


--
-- Name: FUNCTION point_info(x double precision, y double precision); Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT ALL ON FUNCTION api.point_info(x double precision, y double precision) TO web_anon;


--
-- Name: FUNCTION sitemap(); Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT ALL ON FUNCTION api.sitemap() TO web_anon;


--
-- Name: FUNCTION ticket_create(heading text, body text, site_name text); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_create(heading text, body text, site_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_create(heading text, body text, site_name text) TO web_user;


--
-- Name: FUNCTION ticket_get(id uuid); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_get(id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_get(id uuid) TO web_user;


--
-- Name: FUNCTION ticket_list(); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_list() FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_list() TO web_user;


--
-- Name: FUNCTION ticket_reply(id uuid, body text); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_reply(id uuid, body text) FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_reply(id uuid, body text) TO web_user;


--
-- Name: FUNCTION ticket_set_status(id uuid, status text); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_set_status(id uuid, status text) FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_set_status(id uuid, status text) TO web_user;


--
-- Name: FUNCTION ticket_staff_only(); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_staff_only() FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_staff_only() TO web_anon;
GRANT ALL ON FUNCTION api.ticket_staff_only() TO web_user;


--
-- Name: FUNCTION ticket_whoami(); Type: ACL; Schema: api; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION api.ticket_whoami() FROM PUBLIC;
GRANT ALL ON FUNCTION api.ticket_whoami() TO web_user;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT,INSERT ON TABLE public.users TO vhf_login_writer;
GRANT SELECT ON TABLE public.users TO vhf_ticket_writer;


--
-- Name: COLUMN users.id; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT(id) ON TABLE public.users TO vhf_ticket_writer;
GRANT SELECT(id) ON TABLE public.users TO repeater_mail;


--
-- Name: COLUMN users.callsign; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT UPDATE(callsign) ON TABLE public.users TO vhf_login_writer;
GRANT INSERT(callsign) ON TABLE public.users TO vhf_ticket_writer;
GRANT SELECT(callsign) ON TABLE public.users TO repeater_mail;


--
-- Name: COLUMN users.last_seen; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT UPDATE(last_seen) ON TABLE public.users TO vhf_login_writer;


--
-- Name: COLUMN users.email; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT(email),UPDATE(email) ON TABLE public.users TO vhf_ticket_writer;
GRANT SELECT(email) ON TABLE public.users TO repeater_mail;


--
-- Name: FUNCTION user_login(); Type: ACL; Schema: api; Owner: vhf_login_writer
--

REVOKE ALL ON FUNCTION api.user_login() FROM PUBLIC;
GRANT ALL ON FUNCTION api.user_login() TO web_user;


--
-- Name: FUNCTION ticket_current_user(); Type: ACL; Schema: public; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION public.ticket_current_user() FROM PUBLIC;


--
-- Name: TABLE ticket; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.ticket TO vhf_ticket_writer;
GRANT SELECT ON TABLE public.ticket TO repeater_mail;


--
-- Name: FUNCTION ticket_visible(ticket_id uuid, me public.users); Type: ACL; Schema: public; Owner: vhf_ticket_writer
--

REVOKE ALL ON FUNCTION public.ticket_visible(ticket_id uuid, me public.users) FROM PUBLIC;


--
-- Name: FUNCTION trx_networks_autofill(dry_run boolean, max_age interval); Type: ACL; Schema: public; Owner: vhf_owner
--

REVOKE ALL ON FUNCTION public.trx_networks_autofill(dry_run boolean, max_age interval) FROM PUBLIC;


--
-- Name: TABLE scrap_dmr_brandmeister; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dmr_brandmeister TO repeater_scrap;


--
-- Name: TABLE brandmeister_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.brandmeister_status TO web_anon;


--
-- Name: TABLE scrap_dstar_dcs009; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dstar_dcs009 TO repeater_scrap;


--
-- Name: TABLE dcs009_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.dcs009_status TO web_anon;


--
-- Name: TABLE scrap_dmr_ipsc2; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dmr_ipsc2 TO repeater_scrap;


--
-- Name: TABLE ipsc2_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.ipsc2_status TO web_anon;


--
-- Name: TABLE scrap_dstar_ircddb; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dstar_ircddb TO repeater_scrap;


--
-- Name: TABLE ircddb_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.ircddb_status TO web_anon;


--
-- Name: TABLE scrap_c4fm_ycs232; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_c4fm_ycs232 TO repeater_scrap;


--
-- Name: TABLE scrap_dstar_ref096; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dstar_ref096 TO repeater_scrap;


--
-- Name: TABLE scrap_dstar_xlx905; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dstar_xlx905 TO repeater_scrap;


--
-- Name: TABLE scrap_fm_svx_oe9; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_fm_svx_oe9 TO repeater_scrap;


--
-- Name: TABLE scrap_oelink; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_oelink TO repeater_scrap;


--
-- Name: TABLE scrap_tetra_de; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_tetra_de TO repeater_scrap;


--
-- Name: TABLE scrap_tetra_oevsv; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_tetra_oevsv TO repeater_scrap;


--
-- Name: TABLE network_node; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.network_node TO web_anon;


--
-- Name: TABLE oelink_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.oelink_status TO web_anon;


--
-- Name: TABLE ref096_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.ref096_status TO web_anon;


--
-- Name: TABLE svx_oe9_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.svx_oe9_status TO web_anon;


--
-- Name: TABLE tetra_de_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.tetra_de_status TO web_anon;


--
-- Name: TABLE tetra_oevsv_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.tetra_oevsv_status TO web_anon;


--
-- Name: TABLE xlx905_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.xlx905_status TO web_anon;


--
-- Name: TABLE ycs232_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.ycs232_status TO web_anon;


--
-- Name: TABLE network_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.network_status TO web_anon;


--
-- Name: TABLE network; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT ON TABLE public.network TO web_anon;


--
-- Name: TABLE network_unlinked; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.network_unlinked TO web_anon;


--
-- Name: TABLE trx_network; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.trx_network TO web_anon;


--
-- Name: TABLE networks; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.networks TO web_anon;


--
-- Name: TABLE setting_options; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.setting_options TO dz;


--
-- Name: TABLE settings; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.settings TO dz;
GRANT SELECT ON TABLE api.settings TO web_anon;


--
-- Name: TABLE settings2; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.settings2 TO web_anon;


--
-- Name: TABLE site; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.site TO web_anon;


--
-- Name: TABLE site_canonical; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.site_canonical TO web_anon;


--
-- Name: TABLE site_type; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.site_type TO web_anon;


--
-- Name: TABLE trx; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.trx TO web_anon;


--
-- Name: TABLE oesterreich_bev_vgd_lam; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.oesterreich_bev_vgd_lam TO dz;


--
-- Name: TABLE trx_list; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.trx_list TO web_anon;


--
-- Name: TABLE trx_status; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.trx_status TO web_anon;


--
-- Name: TABLE trx_type; Type: ACL; Schema: api; Owner: vhf_owner
--

GRANT SELECT ON TABLE api.trx_type TO web_anon;


--
-- Name: TABLE bands; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT ON TABLE public.bands TO web_anon;


--
-- Name: TABLE dhm; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.dhm TO dz;


--
-- Name: SEQUENCE scrap_c4fm_ycs232_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_c4fm_ycs232_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dmr_brandmeister_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dmr_brandmeister_id_seq TO repeater_scrap;


--
-- Name: TABLE scrap_dmr_ipsc2_hotspot; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dmr_ipsc2_hotspot TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dmr_ipsc2_hotspot_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dmr_ipsc2_hotspot_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dmr_ipsc2_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dmr_ipsc2_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dstar_dcs009_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dstar_dcs009_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dstar_ircddb_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dstar_ircddb_id_seq TO repeater_scrap;


--
-- Name: TABLE scrap_dstar_ref; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_dstar_ref TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dstar_ref096_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dstar_ref096_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dstar_ref_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dstar_ref_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_dstar_xlx905_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_dstar_xlx905_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_fm_svx_oe9_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_fm_svx_oe9_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_oelink_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_oelink_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_tetra_de_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_tetra_de_id_seq TO repeater_scrap;


--
-- Name: SEQUENCE scrap_tetra_oevsv_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_tetra_oevsv_id_seq TO repeater_scrap;


--
-- Name: TABLE scrap_winlink_pactor; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT INSERT ON TABLE public.scrap_winlink_pactor TO repeater_scrap;


--
-- Name: SEQUENCE scrap_winlink_pactor_id_seq; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT USAGE ON SEQUENCE public.scrap_winlink_pactor_id_seq TO repeater_scrap;


--
-- Name: TABLE ticket_config; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT ON TABLE public.ticket_config TO vhf_ticket_writer;


--
-- Name: TABLE ticket_message; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.ticket_message TO vhf_ticket_writer;
GRANT SELECT ON TABLE public.ticket_message TO repeater_mail;


--
-- Name: COLUMN ticket_message.mailed; Type: ACL; Schema: public; Owner: vhf_owner
--

GRANT UPDATE(mailed) ON TABLE public.ticket_message TO repeater_mail;


--
-- PostgreSQL database dump complete
--

\unrestrict edmOrUe6xU0VAeByadN4NSPzLNGzzTGGIjlDCgDB8Gs6Khdktct05dVgAxYngE5

