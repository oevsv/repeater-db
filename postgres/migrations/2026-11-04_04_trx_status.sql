-- Network status per transmitter, for the website: the map shows a network's
-- status under the transmitter linked to it (trx.networks), no longer for the
-- whole site by callsign.
--
-- api.trx_status: one row per link of an active transmitter (api.trx_network),
-- with the status of that node:
--   technologies  the modes the link is about: the transmitter's modes that the
--                 network carries (SVXLink OE9 on an FM transmitter: {fm});
--                 the network's modes if none match (a manual link). The map
--                 pages filter by it (FM page: links with 'fm').
--   text          short info as in api.network_status (by callsign and
--                 network); for XLX905 and REF096 the node's own module only
--                 ("70cm", "B>A"), not those of the callsign's other modules.
--   active        the node is listed now (within 120 minutes; ircDDB: Online).
--   last_active   when the node was last listed.
-- Links to a node the network has never listed are left out.
--
-- api.trx_type: plus trx_uid (at the end), so the website can match the
-- transmitters it shows with api.trx_status.
--
-- Apply as dz (member of vhf_owner) or postgres:
--   psql vhf -f 2026-11-04_04_trx_status.sql

BEGIN;
SET LOCAL ROLE vhf_owner;

CREATE OR REPLACE VIEW api.trx_type AS
 SELECT site_name,
    type_of_station::text = 'repeater_voice'::text AND fm IS TRUE AS fm,
    type_of_station::text = 'repeater_voice'::text AND dmr IS TRUE AS dmr,
    type_of_station::text = 'repeater_voice'::text AND c4fm IS TRUE AS c4fm,
    type_of_station::text = 'repeater_voice'::text AND dstar IS TRUE AS dstar,
    type_of_station::text = 'repeater_voice'::text AND tetra IS TRUE AS tetra,
    type_of_station::text = 'beacon'::text AS beacon,
    type_of_station::text = 'digipeater'::text AS digipeater,
    type_of_station::text = 'atv'::text AS atv,
    COALESCE(vhf_band_name(frequency_tx), vhf_band_name(frequency_rx)) AS band,
    frequency_tx,
    frequency_rx,
    vhf_channel_name(frequency_tx, frequency_rx, 0) AS ch,
    vhf_channel_name(frequency_tx, frequency_rx, 1) AS ch_new,
    callsign,
    antenna_heigth,
    sysop,
    url,
    hardware,
    mmdvm,
    solar_power,
    battery_power,
    fm_wakeup,
    ctcss_tx,
    ctcss_rx,
    echolink,
    echolink_id,
    digital_id,
    cc,
    ipsc2,
    brandmeister,
    c4fm_groups,
    dstar_rpt1,
    other_mode_name,
    comment,
    uid AS trx_uid
   FROM trx
  WHERE status::text = 'active'::text;

CREATE VIEW api.trx_status AS
    SELECT tn.trx_uid,
           tn.site_name,
           tn.callsign,
           tn.network_id,
           tn.network,
           tn.node,
           coalesce(nullif(ARRAY(SELECT x FROM unnest(tn.technologies) x WHERE x = ANY (n.technologies)), '{}'),
                    n.technologies) AS technologies,
           CASE tn.network_id
               WHEN 'xlx905' THEN (SELECT x.band FROM public.scrap_dstar_xlx905 x
                                    WHERE x.dv_station = tn.node ORDER BY x.scraped_timestamp DESC LIMIT 1)
               WHEN 'ref096' THEN (SELECT concat_ws('>', nullif(r.gateway_module, ''), r.reflector_module)
                                     FROM public.scrap_dstar_ref096 r
                                    WHERE r.node = tn.node ORDER BY r.scraped_timestamp DESC LIMIT 1)
               ELSE ns.text
           END AS text,
           tn.listed_now AS active,
           tn.last_listed AS last_active,
           tn.offline
      FROM api.trx_network tn
      JOIN public.network n ON n.id = tn.network_id
      LEFT JOIN api.network_status ns ON ns.callsign = tn.callsign AND ns.network = tn.network
     WHERE tn.trx_status::text = 'active'
       AND tn.last_listed IS NOT NULL;

COMMENT ON VIEW api.trx_status IS 'Network status per transmitter: one row per link in trx.networks of an active transmitter (active = the node is listed now)';

GRANT SELECT ON api.trx_status TO web_anon;

COMMIT;

-- Make PostgREST pick up the new view.
NOTIFY pgrst, 'reload schema';
