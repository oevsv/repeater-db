-- Tickets: staff can delete a ticket with all its messages.
--   api.ticket_delete(id)   staff only (others: error 42501, HTTP 403);
--                           unknown id: 404 (PT404)
-- The messages go with it (foreign key ON DELETE CASCADE). Unsent e-mail
-- notifications of the ticket are dropped too (they are its messages).
--
-- Apply as postgres (the function belongs to vhf_ticket_writer):
--   sudo -u postgres psql vhf -f 2026-11-07_02_ticket_delete.sql

BEGIN;

SET LOCAL ROLE vhf_owner;
GRANT DELETE ON public.ticket TO vhf_ticket_writer;
RESET ROLE;

CREATE FUNCTION api.ticket_delete(id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
    me public.users := public.ticket_current_user();
    t public.ticket;
BEGIN
    IF NOT me.staff4 THEN
        RAISE EXCEPTION 'only staff may delete tickets' USING ERRCODE = '42501';
    END IF;
    t := public.ticket_visible(ticket_delete.id, me);
    DELETE FROM public.ticket WHERE ticket.id = t.id;
END;
$_$;

ALTER FUNCTION api.ticket_delete(uuid) OWNER TO vhf_ticket_writer;
REVOKE ALL ON FUNCTION api.ticket_delete(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.ticket_delete(uuid) TO web_user;

COMMIT;

NOTIFY pgrst, 'reload schema';
