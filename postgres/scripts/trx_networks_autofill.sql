-- Automatic fill of trx.networks (links transmitter <-> network node), see
-- migration 2026-11-03_04_trx_networks.sql and README.md "Network links".
--
--   psql vhf -f trx_networks_autofill.sql              dry run: lists the links it would make
--   psql vhf -v apply=1 -f trx_networks_autofill.sql   makes them
--
-- Safe to run again at any time (e.g. after new nodes appeared or trx data was
-- corrected): it only adds links for nodes and transmitters that have none
-- yet, and never changes a network key that is already set on a transmitter -
-- also not one set to null ("not in this network"). Manual corrections
-- therefore survive. What it can't decide is left in api.network_unlinked.
--
-- Run as dz (member of vhf_owner) or postgres.

\pset pager off

\if :{?apply}
\echo 'Linking (apply=1):'
SELECT * FROM public.trx_networks_autofill(dry_run => false);
\else
\echo 'Dry run - nothing is changed. Run with -v apply=1 to link:'
SELECT * FROM public.trx_networks_autofill(dry_run => true);
\endif

\echo 'Links per network now:'
SELECT id, label, linked, listed_now FROM api.networks ORDER BY sort;

\echo 'Left for manual linking (api.network_unlinked):'
SELECT network_id, node, callsign, last_listed::date,
       (SELECT string_agg(format('%s %s %s%s', c ->> 'trx_uid', c ->> 'site_name', c ->> 'frequency_tx',
                                 CASE WHEN (c ->> 'fits')::boolean THEN '' ELSE ' (mode not carried)' END), '; ')
          FROM jsonb_array_elements(candidates) c) AS candidates
  FROM api.network_unlinked
 ORDER BY network_id, node;
