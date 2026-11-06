-- Tickets: api.ticket_whoami() also returns how many tickets need the user's
-- attention, for the counter in the web page's login button:
--   attention  own tickets with status answered (staff replied)
--              + for staff: all tickets with status open (waiting for staff)
-- Same rule as the highlighted rows on /ticket.
--
-- Apply as postgres (the function belongs to vhf_ticket_writer):
--   sudo -u postgres psql vhf -f 2026-11-06_01_ticket_attention.sql

BEGIN;

-- Same signature: owner (vhf_ticket_writer) and rights stay.
CREATE OR REPLACE FUNCTION api.ticket_whoami() RETURNS json
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
    WITH me AS (SELECT * FROM public.ticket_current_user())
    SELECT json_build_object(
        'staff', me.staff4,
        'attention', (SELECT count(*) FROM public.ticket t
                       WHERE (t.user_id = me.id AND t.status = 'answered')
                          OR (me.staff4 AND t.status = 'open')))
      FROM me;
$_$;

COMMIT;
