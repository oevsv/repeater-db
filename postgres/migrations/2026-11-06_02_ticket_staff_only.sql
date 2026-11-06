-- Tickets: option to restrict the feature to staff (users.staff4), e.g. while
-- it is tested. public.ticket_config holds one row; staff_only = true (set
-- here) means:
--   - every api.ticket_* function answers HTTP 404 for non-staff users
--     (error PT404 from public.ticket_current_user()),
--   - api.ticket_whoami() answers {"enabled": false, ...} instead,
--   - the web page hides all links to /ticket (asks api.ticket_staff_only(),
--     also callable without login).
-- Open the feature to all logged-in users:
--   UPDATE ticket_config SET staff_only = false;
-- No reload or redeploy needed (visitors see the links after loading the page).
--
-- Apply as postgres (the functions belong to vhf_ticket_writer):
--   sudo -u postgres psql vhf -f 2026-11-06_02_ticket_staff_only.sql

BEGIN;

SET LOCAL ROLE vhf_owner;

CREATE TABLE public.ticket_config (
    id boolean DEFAULT true NOT NULL,
    staff_only boolean DEFAULT true NOT NULL,
    CONSTRAINT ticket_config_pkey PRIMARY KEY (id),
    CONSTRAINT ticket_config_one_row CHECK (id)
);

COMMENT ON TABLE public.ticket_config IS 'Ticket settings (one row)';
COMMENT ON COLUMN public.ticket_config.staff_only IS 'true: tickets only for staff (users.staff4), hidden for everyone else';

INSERT INTO public.ticket_config (staff_only) VALUES (true);

GRANT SELECT ON public.ticket_config TO vhf_ticket_writer;

RESET ROLE;

-- As before, plus: error PT404 for non-staff while restricted (no row: restricted).
CREATE OR REPLACE FUNCTION public.ticket_current_user() RETURNS public.users
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
    claims json := nullif(current_setting('request.jwt.claims', true), '')::json;
    user_id uuid := (claims ->> 'sub')::uuid;
    result public.users;
BEGIN
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'not logged in (claim sub missing)' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO result FROM public.users u WHERE u.id = user_id;
    IF NOT FOUND THEN
        INSERT INTO public.users (id, callsign)
        VALUES (user_id, nullif(upper(btrim(claims ->> 'callsign')), ''))
        ON CONFLICT (id) DO NOTHING;
        SELECT * INTO result FROM public.users u WHERE u.id = user_id;
    END IF;
    IF NOT result.staff4 AND coalesce((SELECT c.staff_only FROM public.ticket_config c), true) THEN
        RAISE EXCEPTION 'tickets are restricted to staff' USING ERRCODE = 'PT404';
    END IF;
    RETURN result;
END;
$_$;

-- enabled: the user may use tickets (false: restricted to staff).
CREATE OR REPLACE FUNCTION api.ticket_whoami() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

-- For the web page, also without login (GET /api/rpc/ticket_staff_only).
CREATE FUNCTION api.ticket_staff_only() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $_$
    SELECT coalesce((SELECT c.staff_only FROM public.ticket_config c), true);
$_$;

ALTER FUNCTION api.ticket_staff_only() OWNER TO vhf_ticket_writer;
REVOKE ALL ON FUNCTION api.ticket_staff_only() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.ticket_staff_only() TO web_anon, web_user;

COMMIT;

NOTIFY pgrst, 'reload schema';
