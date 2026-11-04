-- Index for api.brandmeister_status (and so api.network_status / the status
-- lists and api.trx_status).
--
-- api.brandmeister_status takes the latest row of every device
-- (DISTINCT ON (device_id) ... ORDER BY device_id, scraped_timestamp DESC).
-- Without an index that sorts the whole Brandmeister history on every call;
-- with this one the rows come in that order from the index, and the
-- INCLUDE columns (the others the view reads) allow an index-only scan.
-- Measured with about two weeks of history (374,000 rows):
--   brandmeister_status 547 -> 63 ms, network_status 667 -> 186 ms,
--   trx_status 2.6 -> 0.6 s.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-04_05_brandmeister_device_idx.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE INDEX IF NOT EXISTS scrap_dmr_brandmeister_device_ts_idx
    ON public.scrap_dmr_brandmeister (device_id, scraped_timestamp DESC)
    INCLUDE (callsign, hardware, last_seen);

COMMIT;
