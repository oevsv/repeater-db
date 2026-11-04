# Data errors – to fix by hand

Inconsistencies found while connecting the network status (scrapers) with the
repeater database. Most need a decision by a person, not a script. As of 2026-11-03;
the queries below show the current state.

Once the transmitter ↔ network links exist (`trx.networks`, migration
`2026-11-03_04_trx_networks.sql`), many of these show up in
`api.network_unlinked` and on the website page `/networks`.

## 1. One callsign at two sites

A site page is addressed by callsign (`/site/<callsign>`). With a callsign at two
sites, one of them has no URL of its own (also not in the sitemap), and network
status can't be told apart.

| Callsign | Sites |
|---|---|
| OE1XBA | Laaerberg Hochhaus, Porrtower |
| OE5XBR | Froschberg, Stadt/Froschberg |

**To do:** check whether these are really two sites (then one transmitter needs
another callsign or the old one is no longer active) or one site entered twice.

## 2. Transmitter missing in `trx`

Repeater callsigns (OE*X*) listed by a network but not in `trx` at all.

| Callsign | Listed by | Note from the network |
|---|---|---|
| OE4XSM | IPSC2 (ID 232003), Brandmeister (232003), SVXLink OE9 (`OE4XSM-R`) | "Neusiedlersee" / "Breitenbrunn, JN87iw", 439.1 MHz, GM340, 15 W |
| OE9XDW | SVXLink OE9 (`OE9XDW-R`, `OE9XDW-SR`) | "Dornbirn JN47UJ", 438.3875 MHz |
| OE9XGV | SVXLink OE9 (`OE9XGV-HS`), XLX905 (`OE9XGV-B`) | "Clubstation Rankweil", D-STAR module B |
| OE7XHJ | SVXLink OE9 (`OE7XHJ-SR`) | "HF Link zu Rep OE7XTR", 145.1625 MHz – probably a link, not a repeater |
| OE4XLC | Tetra ÖVSV (`OE4XLC-R`) | "Tetra-OE4-LINK" – probably a link, not a repeater |

**To do:** add the missing repeaters to `trx` (site, frequencies, mode); for
links decide whether they belong in `trx` at all.

## 3. Transmitter of the network's mode missing

The callsign is in `trx`, but without an active transmitter of the mode the
network carries.

| Callsign | Site | Listed by | Missing / note |
|---|---|---|---|
| OE8XGK | Finkenstein/Neumüllern | OE-LINK (ID 932882) | FM transmitter (site has DMR only) |
| OE3XAV | Kleinhardersdorf Ort | YCS232 | C4FM transmitter |
| OE3XPA | Kaiserkogel | Brandmeister (232393, TX 438.45) | DMR: the transmitter on 438.45 (uid 2080) is marked C4FM + D-STAR only |
| OE4XBJ | Allhau | Brandmeister (232403, TX 438.325) | DMR transmitter (site has TETRA 430.4125 only) |
| OE7XLI | Hochstein | REF096 (`OE7XLI-B`: module B linked) | D-STAR module B (70 cm): the only D-STAR transmitter is module C, 145.725 (uid 2321) |
| OE6XDF | Dobl | REF096 (`OE6XDF-B`: module B linked) | D-STAR module B (70 cm): only module C, 145.6375 (uid 2140) |
| OE9XFV | Gebhartsberg | Brandmeister (232002, "MMDVM_HBlink", Quantar bridge, TX 438.525) | DMR: 438.525 (uid 2224) is FM only – bridge or DMR repeater? |
| OE6XAG | Schöckl | Tetra ÖVSV (`OE6XAG-R`, "Tetra-Schoeckl/430.4125") | TETRA transmitter |
| OE6XBF | Stradner Kogel | Tetra ÖVSV (`OE6XBF-R`, "Tetra-Stradnerkogel/430.3125") | TETRA transmitter |
| OE3XWW | Mönichkirchen Schwaig | Tetra ÖVSV (`OE3XWW-R`, "Tetra-Mönichkirchen/430.2375") | TETRA transmitter |
| OE6XAG | Schöckl | DCS009 | D-STAR transmitter (or not on DCS009 any more) |
| OE7XOT | Obtarrenz | SVXLink OE9 (`OE7XOT-R`, 438.1 MHz) | no FM / TETRA transmitter (439.1 is DMR + D-STAR, uid 2347 and 2422 have no mode) |

Not errors: OE9XVD (Bludenz Mitte, TETRA DMO 432.8 MHz) is on SVXLink OE9 – a
TETRA transmitter in a mixed network, linked by frequency. Likewise the Tetra
ÖVSV and SVXLink OE9 reflectors link FM repeaters
(e.g. `OE1XCS-R`, `OE3XFC-R`, `OE6XDD-R` on 23 cm, `OE4XUB-R`). These are FM
transmitters linked into a mixed network; they get linked like any other
transmitter (`trx.networks`).

## 4. Frequency or ID differs from the network

| Callsign | Network says | `trx` says |
|---|---|---|
| OE1XCS (Laaerberg) | Tetra ÖVSV `OE1XCS-T`: 430.3375 MHz | TETRA transmitter 430.7125 MHz |
| OE7XLI | OE-LINK repeater ID 932873 | `digital_id` 232710 on the FM transmitter 438.875 MHz (a DMR-style ID on an FM transmitter) |
| OE8XMK | IPSC2 repeater ID 232803 | DMR transmitter `digital_id` 232802 (FM 438.575 has 932881 = OE-LINK, correct) |
| OE3XVJ | IPSC2 repeater ID 232085 | DMR transmitter without `digital_id` |
| OE3XWW | IPSC2 repeater ID 232307 | DMR transmitter without `digital_id` |
| OE2XHL (Kitzsteinhorn) | SVXLink OE9 `OE2XHL-R`: TX 146.05 MHz | FM transmitter 145.65 MHz |
| OE6XAG (Schöckl) | Tetra ÖVSV `OE6XAG-R`: 430.4125 MHz | same frequency as OE3XIR (Hegerberg) – check |

**To do:** correct `trx.frequency_tx` / `trx.digital_id`. A correct
`digital_id` lets the automatic fill link OE-LINK and IPSC2 exactly
(`trx_networks_autofill()`, rule `digital_id`).

## 5. Nodes the automatic fill could not link

After `trx_networks_autofill.sql` (104 links incl. Brandmeister), these mixed-network nodes need a
person (see `api.network_unlinked` for all, with candidate transmitters):

| Node | Reports | Candidates / reason |
|---|---|---|
| SVXLink `OE7XLH-R` | no frequency | probably FM 438.625 (uid 2170) |
| SVXLink `OE7XTR-R` | 431.0 (default value) | probably FM 145.7625 (uid 2180) |
| SVXLink `OE2XHL-R` | 146.05 | FM 145.65 (uid 2044), see 4. |
| Tetra `OE4XBJ-T` | no frequency ("Tetra-88-LINK") | TETRA 430.4125 (uid 2341); Tetra-DE lists `OE4XBJ-R` with 430.4125 and links it there |
| Tetra `OE1XCS-T` | 430.3375 | TETRA 430.7125 (uid 2423), see 4. |
| Tetra `OE3XWW-R`, `OE6XAG-R`, `OE6XBF-R` | 430.2375, 430.4125, 430.3125 | TETRA transmitter missing, see 3. |
| Tetra `OE4XUB-R` | no frequency ("Tetra-88-LINK") | link of the FM repeater? FM 145.775 / 438.55 |
| Brandmeister `232072` (OE8XGK) | 438.45, last seen 2026-10-22 | old second registration; 232836 is linked – set `{"brandmeister": ...}` only if it is a separate device |

## 6. Several transmitters of one mode under one callsign

19 callsigns have more than one active FM transmitter (3 more than one DMR
transmitter), e.g. OE3XNR: FM 145.6375 and 438.875 MHz. Not an error, but a
network status can only be assigned to the right transmitter with an explicit
link in `trx.networks` (OE3XNR: OE-LINK is on 438.875, `digital_id` 932832).
The automatic fill skips such callsigns unless the `digital_id` matches; they
appear in `api.network_unlinked` with all candidate transmitters.

**To do:** link the remaining ones by hand, see "Manual corrections" in
`README.md` (Network links).

## 7. Errors in the sources (not ours)

| Source | Entry | Problem |
|---|---|---|
| SVXLink OE9 | `OE7HCG-HS` | location sent with invalid characters ("M򴺠/ Tirol", probably "Mötz") |
| SVXLink OE9 | many hotspots | placeholder values ("50.xxxx", "OE0XXX Name JNnnXX") |
| ircDDB | OE4XBJ, OE1XIK | listed, but always Offline – probably historic registrations. OE4XBJ (Allhau) has no D-STAR transmitter in `trx` (TETRA only), OE1XIK is not in `trx`. Ignored since migration `2026-11-04_01_ircddb_offline.sql` (only Online counts). |

**To do:** tell the reflector operators if it matters; nothing to fix here.

## Queries

```sql
-- 1. callsign at several sites
SELECT upper(callsign), string_agg(DISTINCT site_name, ' | ')
  FROM trx WHERE status = 'active' AND coalesce(callsign, '') <> ''
 GROUP BY 1 HAVING count(DISTINCT site_name) > 1;

-- 2.-6. nodes a network lists that are not linked to a transmitter, with the
-- candidate transmitters (after migration 2026-11-03_04_trx_networks.sql)
SELECT * FROM api.network_unlinked ORDER BY network_id, node;
```
