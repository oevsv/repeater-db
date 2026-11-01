-- Users who logged in via OpenID Connect (Keycloak, realm oevsv), and
-- api.user_login() to record a login.
--
-- public.users
--   id          the OpenID subject ("sub"), Keycloak's stable user id (a UUID);
--               not the e-mail or the callsign, which can change
--   callsign    from the login (preferred_username), upper case; may be NULL
--   first_seen  first login
--   last_seen   latest login
--
-- api.user_login()  (POST /api/rpc/user_login, no parameters)
--   Called by the web page's login service (auth-prototype) right after a
--   successful login, with the PostgREST token it mints for the user (role
--   web_user). The user is taken from that verified token's claims (sub,
--   callsign), never from parameters, so nobody can record a login for
--   someone else. New user: inserts it (first_seen = last_seen = now). Known
--   user: updates the callsign and sets last_seen. Returns the user row.
--
-- Roles: web_user is the PostgREST role for logged-in users (PGRST_ROLE of the
-- login service). It is created here if missing and granted to the PostgREST
-- login role authenticator, if that exists. Like web_anon it can't log in.
--
-- Apply:  psql vhf -f 2026-11-01_users.sql   (as postgres: creates a role)

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_user') THEN
        CREATE ROLE web_user NOLOGIN;
    END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticator') THEN
        GRANT web_user TO authenticator;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA api TO web_user;

CREATE TABLE public.users (
    id uuid NOT NULL,
    callsign character varying(20),
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);

ALTER TABLE public.users OWNER TO dz;

COMMENT ON TABLE public.users IS 'Users who logged in via OpenID Connect; written by api.user_login()';
COMMENT ON COLUMN public.users.id IS 'OpenID subject (sub) from Keycloak';
COMMENT ON COLUMN public.users.callsign IS 'Callsign from the latest login (preferred_username, upper case); may be NULL';

-- SECURITY DEFINER: runs as its owner (dz), so web_user needs no rights on the
-- table itself; the empty search_path makes every name explicit.
CREATE FUNCTION api.user_login() RETURNS public.users
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

ALTER FUNCTION api.user_login() OWNER TO dz;

-- Only logged-in users may call it (functions are executable by PUBLIC by default).
REVOKE ALL ON FUNCTION api.user_login() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.user_login() TO web_user;

COMMIT;

-- Make PostgREST pick up the new function.
NOTIFY pgrst, 'reload schema';
