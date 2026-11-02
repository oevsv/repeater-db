-- Owner roles: the schema objects no longer belong to the admin login dz.
--
--  vhf_owner         owns all tables, views, sequences and functions that dz
--                    owned. Can't log in; dz is a member, so dz keeps full
--                    control. Future migrations: SET ROLE vhf_owner at the
--                    start, so new objects belong to it too.
--  vhf_login_writer  owns api.user_login() only. That function is SECURITY
--                    DEFINER (runs with its owner's rights), so its owner gets
--                    just what it needs: read and insert users, update their
--                    callsign and last_seen. It can't log in.
--
-- Not changed: the database vhf itself (stays with its current owner), the
-- schemas (owned by postgres), the PostGIS objects (owned by postgres), and
-- the rights of web_anon, web_user, authenticator and repeater_scrap.
--
-- Apply as postgres (creates roles, changes owners):
--   sudo -u postgres psql vhf -f 2026-11-02_owner_roles.sql
-- Can be run again; it only moves objects still owned by dz.

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vhf_owner') THEN
        CREATE ROLE vhf_owner NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vhf_login_writer') THEN
        CREATE ROLE vhf_login_writer NOLOGIN;
    END IF;
END
$$;

-- dz administers through vhf_owner (inherits its rights, can SET ROLE to it).
GRANT vhf_owner TO dz;

-- vhf_owner creates the objects of future migrations in these schemas.
GRANT USAGE, CREATE ON SCHEMA public, api TO vhf_owner;

-- Move everything dz owns in this database's schemas. Tables first: their
-- indexes, TOAST tables and column sequences follow them.
DO $$
DECLARE
    obj record;
BEGIN
    FOR obj IN
        SELECT c.oid::regclass AS name,
               CASE c.relkind WHEN 'S' THEN 'SEQUENCE' WHEN 'v' THEN 'VIEW'
                              WHEN 'm' THEN 'MATERIALIZED VIEW' WHEN 'f' THEN 'FOREIGN TABLE'
                              ELSE 'TABLE' END AS kind
          FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
         WHERE c.relowner = 'dz'::regrole
           AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
           AND n.nspname NOT IN ('pg_catalog', 'information_schema')
         ORDER BY c.relkind IN ('r', 'p') DESC, c.relkind = 'S' DESC
    LOOP
        -- a column sequence may already have moved with its table
        IF (SELECT relowner FROM pg_catalog.pg_class WHERE oid = obj.name) = 'dz'::regrole THEN
            EXECUTE format('ALTER %s %s OWNER TO vhf_owner', obj.kind, obj.name);
        END IF;
    END LOOP;

    FOR obj IN
        SELECT p.oid::regprocedure AS name
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
         WHERE p.proowner = 'dz'::regrole
           AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE format('ALTER ROUTINE %s OWNER TO vhf_owner', obj.name);
    END LOOP;
END
$$;

-- api.user_login(): minimal owner. INSERT ... ON CONFLICT DO UPDATE ...
-- RETURNING needs SELECT, INSERT and UPDATE of the updated columns.
GRANT USAGE ON SCHEMA public TO vhf_login_writer;
GRANT SELECT, INSERT ON public.users TO vhf_login_writer;
GRANT UPDATE (callsign, last_seen) ON public.users TO vhf_login_writer;
ALTER FUNCTION api.user_login() OWNER TO vhf_login_writer;

COMMIT;
