-- Tickets: e-mail notification for every message (the first text and every
-- reply) to the ticket's author and to the VHF management (ukw@oevsv.at).
-- Sent by scripts/ticket_mail.py (service repeater-ticket-mail), not by the
-- database:
--   public.users.email           the author's address, from the login (claim
--                                email of the SSO), stored by
--                                public.ticket_current_user() on every ticket call
--   public.ticket_message.mailed NULL: notification not sent yet
--   trigger ticket_message_mail  NOTIFY ticket_mail on every new message, so the
--                                service sends at once (it also checks every 5 min)
--   role repeater_mail           the service's login (peer authentication over the
--                                local socket, as the system user repeater_mail; no
--                                password): reads tickets, sets mailed
-- Existing messages count as mailed (no mails for old messages).
--
-- Apply as postgres (creates a role):
--   sudo -u postgres psql vhf -f 2026-11-06_03_ticket_mail.sql

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'repeater_mail') THEN
        CREATE ROLE repeater_mail LOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO repeater_mail;

SET LOCAL ROLE vhf_owner;

ALTER TABLE public.users ADD COLUMN email character varying(254);
COMMENT ON COLUMN public.users.email IS 'E-mail from the login (SSO), for ticket notifications; stored by ticket_current_user()';

ALTER TABLE public.ticket_message ADD COLUMN mailed timestamp with time zone;
COMMENT ON COLUMN public.ticket_message.mailed IS 'E-mail notification sent (scripts/ticket_mail.py); NULL: not yet';
UPDATE public.ticket_message SET mailed = created;

CREATE INDEX ticket_message_unmailed_idx ON public.ticket_message (created) WHERE mailed IS NULL;

CREATE FUNCTION public.ticket_message_mail() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $_$
BEGIN
    PERFORM pg_notify('ticket_mail', NEW.id::text);
    RETURN NULL;
END;
$_$;

CREATE TRIGGER ticket_message_mail AFTER INSERT ON public.ticket_message
    FOR EACH ROW EXECUTE FUNCTION public.ticket_message_mail();

GRANT INSERT (email), UPDATE (email) ON public.users TO vhf_ticket_writer;

-- The mail service: read, and mark as mailed (UPDATE also allows FOR UPDATE).
GRANT SELECT (id, callsign, email) ON public.users TO repeater_mail;
GRANT SELECT ON public.ticket, public.ticket_message TO repeater_mail;
GRANT UPDATE (mailed) ON public.ticket_message TO repeater_mail;

RESET ROLE;

-- As before, plus: stores the e-mail from the token (claim email).
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
    ELSIF new_email IS NOT NULL AND new_email IS DISTINCT FROM result.email THEN
        UPDATE public.users u SET email = new_email WHERE u.id = user_id
        RETURNING * INTO result;
    END IF;
    IF NOT result.staff4 AND coalesce((SELECT c.staff_only FROM public.ticket_config c), true) THEN
        RAISE EXCEPTION 'tickets are restricted to staff' USING ERRCODE = 'PT404';
    END IF;
    RETURN result;
END;
$_$;

COMMIT;
