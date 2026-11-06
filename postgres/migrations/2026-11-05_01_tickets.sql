-- Tickets: logged-in users submit updates (a heading and a text), see their
-- own submissions and the answers; staff see and answer all of them.
-- Website: /ticket (list + new), /ticket/<uuid> (one ticket with its messages).
--
-- public.users.staff4   true: the user is staff (sees and answers all tickets).
--                       Set by hand, e.g.
--                         UPDATE users SET staff4 = true WHERE callsign = 'OE1ABC';
--                       api.user_login() never changes it.
-- public.ticket         id (uuid, used in the URL), author, heading, status,
--                       optional site_name (the site the update is about),
--                       created, updated (last message or status change).
--                       status: open      waiting for staff
--                               answered  staff replied, waiting for the user
--                               closed    done (a new message reopens it)
-- public.ticket_message the first text and every reply; staff = written by staff.
--
-- Access only through the functions below (POST /api/secure/rpc/...), with the
-- user taken from the verified token (claim sub), never from parameters. They
-- are SECURITY DEFINER, owned by vhf_ticket_writer, which may do just this.
-- The web roles get no rights on the tables.
--   api.ticket_whoami()                       {"staff": bool}
--   api.ticket_list()                         own tickets; staff: all
--   api.ticket_get(id)                        one ticket with its messages (json)
--   api.ticket_create(heading, body, site_name) -> the new ticket's id
--   api.ticket_reply(id, body)                user: status open; staff: answered
--   api.ticket_set_status(id, status)         author: closed / open; staff: any
-- A user missing in public.users (login not recorded) is added on first use.
--
-- Apply as postgres (creates a role):
--   sudo -u postgres psql vhf -f 2026-11-05_01_tickets.sql

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vhf_ticket_writer') THEN
        CREATE ROLE vhf_ticket_writer NOLOGIN;
    END IF;
END
$$;

-- As postgres: the schemas belong to postgres.
GRANT USAGE ON SCHEMA public, api TO vhf_ticket_writer;

SET LOCAL ROLE vhf_owner;

ALTER TABLE public.users ADD COLUMN staff4 boolean DEFAULT false NOT NULL;
COMMENT ON COLUMN public.users.staff4 IS 'Staff: sees and answers all tickets (set by hand)';

CREATE TABLE public.ticket (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    heading character varying(200) NOT NULL,
    status text DEFAULT 'open' NOT NULL,
    site_name character varying(100),
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ticket_pkey PRIMARY KEY (id),
    CONSTRAINT ticket_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
    CONSTRAINT ticket_status_check CHECK (status IN ('open', 'answered', 'closed')),
    CONSTRAINT ticket_heading_check CHECK (btrim(heading) <> '')
);

COMMENT ON TABLE public.ticket IS 'Updates submitted by logged-in users (website /ticket); written by the api.ticket_* functions';
COMMENT ON COLUMN public.ticket.id IS 'Ticket id, in the URL /ticket/<id>';
COMMENT ON COLUMN public.ticket.status IS 'open: waiting for staff, answered: waiting for the user, closed: done';
COMMENT ON COLUMN public.ticket.site_name IS 'Site the update is about (optional, as given; no foreign key: site names are not unique)';
COMMENT ON COLUMN public.ticket.updated IS 'Last message or status change';

CREATE INDEX ticket_user_idx ON public.ticket (user_id, updated DESC);
CREATE INDEX ticket_updated_idx ON public.ticket (updated DESC);

CREATE TABLE public.ticket_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    user_id uuid NOT NULL,
    staff boolean DEFAULT false NOT NULL,
    body text NOT NULL,
    created timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT ticket_message_pkey PRIMARY KEY (id),
    CONSTRAINT ticket_message_ticket_fkey FOREIGN KEY (ticket_id) REFERENCES public.ticket(id) ON DELETE CASCADE,
    CONSTRAINT ticket_message_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
    CONSTRAINT ticket_message_body_check CHECK (btrim(body) <> '' AND length(body) <= 20000)
);

COMMENT ON TABLE public.ticket_message IS 'Messages of a ticket: the submitted text and the replies';
COMMENT ON COLUMN public.ticket_message.created IS 'clock_timestamp(): keeps the order of messages written in one transaction';
COMMENT ON COLUMN public.ticket_message.staff IS 'Written by staff (users.staff4 at that time)';

CREATE INDEX ticket_message_ticket_idx ON public.ticket_message (ticket_id, created);

-- The functions' owner: reads users, adds a missing user, writes tickets.
GRANT SELECT ON public.users TO vhf_ticket_writer;
GRANT INSERT (id, callsign) ON public.users TO vhf_ticket_writer;
GRANT SELECT, INSERT, UPDATE ON public.ticket, public.ticket_message TO vhf_ticket_writer;

-- The current user from the token (claim sub, callsign); added to
-- public.users if the login was not recorded. Error 42501 (PostgREST: 401/403)
-- without a user.
CREATE FUNCTION public.ticket_current_user() RETURNS public.users
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
    RETURN result;
END;
$_$;

-- A ticket the current user may see (author or staff), else error PT404
-- (PostgREST answers HTTP 404). Same answer for "missing" and "not yours".
CREATE FUNCTION public.ticket_visible(ticket_id uuid, me public.users) RETURNS public.ticket
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

CREATE FUNCTION api.ticket_whoami() RETURNS json
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
    SELECT json_build_object('staff', (public.ticket_current_user()).staff4);
$_$;

CREATE FUNCTION api.ticket_list()
    RETURNS TABLE (id uuid, heading character varying, status text, site_name character varying,
                   created timestamp with time zone, updated timestamp with time zone,
                   author_callsign character varying, own boolean, messages bigint, last_from_staff boolean)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

CREATE FUNCTION api.ticket_get(id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

CREATE FUNCTION api.ticket_create(heading text, body text, site_name text DEFAULT NULL) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

CREATE FUNCTION api.ticket_reply(id uuid, body text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

CREATE FUNCTION api.ticket_set_status(id uuid, status text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;

-- ticket_list and ticket_get are not STABLE: they may add a missing user.
-- Owner change as postgres: vhf_owner is no member of vhf_ticket_writer.
RESET ROLE;
ALTER FUNCTION public.ticket_current_user() OWNER TO vhf_ticket_writer;
ALTER FUNCTION public.ticket_visible(uuid, public.users) OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_whoami() OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_list() OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_get(uuid) OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_create(text, text, text) OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_reply(uuid, text) OWNER TO vhf_ticket_writer;
ALTER FUNCTION api.ticket_set_status(uuid, text) OWNER TO vhf_ticket_writer;

-- Functions are executable by PUBLIC by default: only logged-in users
-- (web_user) may call the api ones; the helpers only by their owner.
REVOKE ALL ON FUNCTION public.ticket_current_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ticket_visible(uuid, public.users) FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_whoami() FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_list() FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_get(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_create(text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_reply(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION api.ticket_set_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.ticket_whoami() TO web_user;
GRANT EXECUTE ON FUNCTION api.ticket_list() TO web_user;
GRANT EXECUTE ON FUNCTION api.ticket_get(uuid) TO web_user;
GRANT EXECUTE ON FUNCTION api.ticket_create(text, text, text) TO web_user;
GRANT EXECUTE ON FUNCTION api.ticket_reply(uuid, text) TO web_user;
GRANT EXECUTE ON FUNCTION api.ticket_set_status(uuid, text) TO web_user;

COMMIT;

-- Make PostgREST pick up the new functions.
NOTIFY pgrst, 'reload schema';
