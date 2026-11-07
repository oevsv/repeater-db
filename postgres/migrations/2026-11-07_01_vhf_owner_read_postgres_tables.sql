-- Fix after 2026-11-02_02_owner_roles.sql: a few tables belong to postgres
-- (imported data), and only dz had rights on them. The views moved to
-- vhf_owner, and a view reads its tables with its owner's rights, so these
-- failed with "permission denied for table ...":
--   api.trx_list (public.trx_list, public.trx_verylong)  oesterreich_bev_vgd_lam
--   api.settings2                                         setting_options
-- vhf_owner may read them (the tables stay with postgres). dhm too: dz could
-- read it, so objects of future migrations can as well.
--
-- Apply as postgres (owner of the tables):
--   sudo -u postgres psql vhf -f 2026-11-07_01_vhf_owner_read_postgres_tables.sql

BEGIN;

GRANT SELECT ON public.oesterreich_bev_vgd_lam, public.setting_options, public.dhm TO vhf_owner;

COMMIT;
