-- Foreign key trx.site_name -> site.site_name: every transmitter belongs to an
-- existing site.
--
--  * ON DELETE RESTRICT: a site that still has transmitters can't be deleted
--    (delete or move its transmitters first);
--  * ON UPDATE CASCADE: renaming a site renames it in its transmitters too.
--  * trx.site_name becomes NOT NULL (a transmitter without site isn't allowed).
--
-- The key referenced is site.site_name (unique index site_name_idx); site.uid
-- stays the primary key.
--
-- Apply:  psql vhf -f 2026-11-02_01_trx_site_fk.sql
-- Fails with a list of the offending transmitters if some have no site or an
-- unknown one; fix those first.

BEGIN;

DO $$
DECLARE
    bad text;
BEGIN
    SELECT string_agg(format('uid %s (%s): site %s', t.uid, t.callsign, coalesce(quote_literal(t.site_name), 'NULL')),
                      E'\n' ORDER BY t.uid)
      INTO bad
      FROM public.trx t
     WHERE t.site_name IS NULL
        OR NOT EXISTS (SELECT FROM public.site s WHERE s.site_name = t.site_name);
    IF bad IS NOT NULL THEN
        RAISE EXCEPTION E'transmitters without a known site:\n%', bad;
    END IF;
END
$$;

ALTER TABLE public.trx
    ALTER COLUMN site_name SET NOT NULL,
    ADD CONSTRAINT trx_site_fk FOREIGN KEY (site_name) REFERENCES public.site (site_name)
        ON UPDATE CASCADE ON DELETE RESTRICT;

COMMIT;
