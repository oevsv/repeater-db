-- E-mail addresses are kept only while the user is active: after 4 weeks
-- without activity users.email is cleared (it comes back with the next
-- ticket call after a login, from the SSO).
--   public.users.last_active  last login or ticket use (any page view while
--                             logged in calls api.ticket_whoami()); stored at
--                             most once per hour by ticket_current_user()
--   api.user_login()          also sets last_active, and clears the e-mail of
--                             all OTHER users inactive for more than 28 days
-- Mails for a ticket whose author has no address go to ukw@oevsv.at only.
--
-- Apply as postgres (functions belong to vhf_login_writer / vhf_ticket_writer):
--   sudo -u postgres psql vhf -f 2026-11-07_03_email_retention.sql

BEGIN;

SET LOCAL ROLE vhf_owner;

ALTER TABLE public.users ADD COLUMN last_active timestamp with time zone DEFAULT now() NOT NULL;
COMMENT ON COLUMN public.users.last_active IS 'Last login or ticket use; users.email is cleared 28 days after it (api.user_login())';
UPDATE public.users SET last_active = last_seen;

GRANT UPDATE (last_active, email) ON public.users TO vhf_login_writer;
GRANT UPDATE (last_active) ON public.users TO vhf_ticket_writer;

RESET ROLE;

-- As before, plus: last_active, and clearing the e-mail of inactive users.
CREATE OR REPLACE FUNCTION api.user_login() RETURNS public.users
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

    INSERT INTO public.users AS u (id, callsign, first_seen, last_seen, last_active)
    VALUES (user_id, user_callsign, now(), now(), now())
    ON CONFLICT (id) DO UPDATE
        SET callsign = EXCLUDED.callsign,
            last_seen = now(),
            last_active = now()
    RETURNING u.* INTO result;

    -- E-mail of users inactive for 4 weeks.
    UPDATE public.users u SET email = NULL
     WHERE u.email IS NOT NULL
       AND u.last_active < now() - interval '28 days'
       AND u.id <> user_id;

    RETURN result;
END;
$_$;

-- As before, plus: last_active (at most once per hour, not on every page view).
CREATE OR REPLACE FUNCTION public.ticket_current_user() RETURNS public.users
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
    ELSIF (new_email IS NOT NULL AND new_email IS DISTINCT FROM result.email)
          OR result.last_active < now() - interval '1 hour' THEN
        UPDATE public.users u
           SET email = coalesce(new_email, u.email), last_active = now()
         WHERE u.id = user_id
        RETURNING * INTO result;
    END IF;
    IF NOT result.staff4 AND coalesce((SELECT c.staff_only FROM public.ticket_config c), true) THEN
        RAISE EXCEPTION 'tickets are restricted to staff' USING ERRCODE = 'PT404';
    END IF;
    RETURN result;
END;
$_$;

COMMIT;
