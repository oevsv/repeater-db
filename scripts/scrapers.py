"""The scraped sources: one function per scrap_* table (same name).

Each returns the number of rows inserted and raises on failure; see
scrap_common.py for the shared download / parse / store code and the callsign
rules, scrap_all.py to run them.
"""

import os
import re

import requests

from scrap_common import (ScrapError, base_callsign, callsign, dmr_record, fetch, find_all, get_soup, row_cells,
                          save, scrap_dmr_status_page, scrap_status_page)


# --- DMR -------------------------------------------------------------------

def scrap_dmr_ipsc2():
    return scrap_dmr_status_page("https://ipsc2.oevsv.at/_status.html", "scrap_dmr_ipsc2")


def scrap_dmr_ipsc2_de():
    """The German IPSC2 server (same dashboard as the OEVSV IPSC2). Only
    Austrian callsigns ("OE" + digit) are stored: not the German repeaters and
    not the network names like "OE-MLINK"."""
    def oe_record(row):
        record = dmr_record(row)
        return record if record and re.match(r"OE\d", record["callsign"]) else None
    return scrap_status_page("https://ipsc2-dl-rptr.xreflector.net/_status.html", "scrap_dmr_ipsc2_de", oe_record)


def scrap_dmr_ipsc2_hotspot():
    return scrap_dmr_status_page("https://dmo.oevsv.at/_status.html", "scrap_dmr_ipsc2_hotspot")


def scrap_dmr_brandmeister():
    """DMR devices (repeaters and hotspots) on the Austrian Brandmeister master
    2322, from the Brandmeister API (the dashboard https://brandmeister.network/
    itself uses a WebSocket). Only Austrian callsigns (OE...) are stored; the
    master also serves neighbouring countries. The list contains devices last
    seen up to about a month ago - "last_seen" (UTC) tells whether one is on
    the air, not the listing. Some callsigns carry a place ("OE9XKV Dornbirn");
    "callsign" has it without."""
    url = "https://api.brandmeister.network/v2/device/byMaster/2322"
    try:
        devices = fetch(url).json()
    except ValueError as e:
        raise ScrapError(f"{url}: no JSON ({e})") from e
    if not isinstance(devices, list):
        raise ScrapError(f"{url}: expected a list of devices")

    def to_record(device):
        if not isinstance(device, dict) or not callsign(device.get("callsign")).startswith("OE"):
            return None

        def text(key):
            value = device.get(key)
            return "" if value is None else str(value).strip()

        return {"callsign": base_callsign(device["callsign"]), "device_id": text("id"),
                "device_callsign": text("callsign"), "status": text("status"),
                "last_seen": device.get("last_seen") or None, "tx": text("tx"), "rx": text("rx"),
                "colorcode": text("colorcode"), "hardware": text("hardware"), "firmware": text("firmware"),
                "city": text("city"), "lat": text("lat"), "lng": text("lng"), "master": text("lastKnownMaster")}

    return save("scrap_dmr_brandmeister", devices, to_record)


# --- FM --------------------------------------------------------------------

def scrap_oelink():
    return scrap_dmr_status_page("https://oe-link.oevsv.at/_status.html", "scrap_oelink")


def scrap_fm_svx_oe9():
    """Nodes of the SVXLink reflector OE9 (dashboard https://svx.oe9hamnet.at/,
    which loads this JSON). Only nodes with monitored talkgroups; others are
    bridges / links without own traffic. Nodes are keyed by callsign with suffix
    ("OE9XVV-R", "OE9KHJ-HS"); "callsign" has it without. Most nodes describe
    one QTH with one transmitter (module "K"), many with default / dummy values;
    the first of each is stored. The keys vary in case between node versions."""
    url = "https://svx.oe9hamnet.at/reflector_proxy/"
    try:
        nodes = fetch(url).json()["nodes"]
    except (ValueError, KeyError, TypeError) as e:
        raise ScrapError(f"{url}: no JSON with 'nodes' ({e})") from e

    def first(mapping, *keys):
        """The value of the first of keys present in mapping, as text ("" if none)."""
        for key in keys:
            value = (mapping or {}).get(key)
            if value not in (None, ""):
                return str(value).strip()
        return ""

    def to_record(item):
        node, info = item
        if not isinstance(info, dict) or not info.get("monitoredTGs"):
            return None
        qth = (info.get("qth") or [{}])[0] or {}
        pos = qth.get("pos") or {}
        tx = next(iter((qth.get("tx") or {}).values()), {}) or {}
        return {"callsign": base_callsign(node), "node": node.strip(),
                "monitored_tgs": " ".join(str(tg) for tg in info["monitoredTGs"]),
                "node_location": first(info, "nodeLocation", "NodeLocation", "Location") or first(qth, "name"),
                "sysop": first(info, "sysop", "Sysop", "SysOp"),
                "tx_freq": first(tx, "freq"), "tx_name": first(tx, "name"), "tx_pwr": first(tx, "pwr"),
                "lat": first(pos, "lat") or first(info, "LAT"), "long": first(pos, "long") or first(info, "LONG")}

    if not isinstance(nodes, dict):
        raise ScrapError(f"{url}: 'nodes' is not an object")
    return save("scrap_fm_svx_oe9", nodes.items(), to_record)


# --- C4FM ------------------------------------------------------------------

def scrap_c4fm_ycs232():
    def to_record(row):
        # 10 cells: Nr, Repeater ("station (group)"), Name, QRG, ID, DG-ID,
        #           NAME2, RX/TX, MODE, TYPE
        cells = row_cells(row, 10)
        if cells is None:
            return None
        nr, repeater, name, qrg, repeater_id, dg_id, name2, rx_tx, mode, type_ = cells
        # "OE1GPA     (05)" -> station "OE1GPA", group "05". Split at the last
        # "(" so a station with blanks ("FCS22820  -335555") stays whole.
        station, group_code = repeater, ""
        if "(" in repeater:
            station, group = repeater.rsplit("(", 1)
            station, group_code = station.strip(), group.replace(")", "").strip()
        # station: as listed, e.g. "HB9DR-2", "FCS22820  -335555", "DVMatrix"
        return {"nr": nr, "callsign": base_callsign(station), "station": station,
                "group_code": group_code, "name": name, "qrg": qrg, "repeater_id": repeater_id,
                "dg_id": dg_id, "name2": name2, "rx_tx": rx_tx, "mode": mode, "type": type_}

    return scrap_status_page("https://ycs232.oevsv.at/_status.html", "scrap_c4fm_ycs232", to_record)


# --- D-STAR ----------------------------------------------------------------

def scrap_dstar_dcs009():
    def to_record(row):
        # 8 cells: Nr, DV Station, Band, Linked, DCS GROUP, via, Software, HB-Timer
        cells = row_cells(row, 8)
        if cells is None:
            return None
        nr, station, band, linked, dcs_group, via, software, hb_timer = cells
        return {"nr": nr, "callsign": callsign(station), "band": band, "linked": linked,
                "dcs_group": dcs_group, "via": via, "software": software, "hb_timer": hb_timer}

    return scrap_status_page("https://xlx232.oevsv.at/_status.html", "scrap_dstar_dcs009", to_record)


def scrap_dstar_xlx905():
    url = "http://xlx905.oevsv.at:8888/index.php?show=repeaters"

    def to_record(row):
        # 9 cells: #, Flag, DV Station ("OE9XGV-B"), Band, Last Heard,
        #          Linked for, Protocol, Module, IP
        cells = row_cells(row, 9)
        if cells is None:
            return None
        no, flag, dv_station, band, last_heard, linked_for, protocol, module, ip = cells
        return {"no": no, "flag": flag, "callsign": base_callsign(dv_station),
                "dv_station": dv_station, "band": band, "last_heard": last_heard,
                "linked_for": linked_for, "protocol": protocol, "module": module, "ip_address": ip}

    table = get_soup(url).find("table", class_="listingtable")
    if not table:
        raise ScrapError(f"{url}: no table with class='listingtable' found")
    # The first two rows are headings (titles, filter inputs).
    return save("scrap_dstar_xlx905", table.find_all("tr")[2:], to_record)


# --- EchoLink --------------------------------------------------------------

ECHOLINK_URL = "https://www.echolink.org/links.jsp?d=2&sel=all&offset={}"
ECHOLINK_COLUMNS = ["station", "description", "node_number", "lat_lon", "grid_square", "place",
                    "frequency", "tone", "power", "haat", "antenna", "status", "comment", "last_update"]


def scrap_echolink():
    """EchoLink links (-R repeaters, -L simplex links) that are online, from the
    worldwide list https://www.echolink.org/links.jsp (Online only, 200 per
    page, sorted by callsign). Its country filter has no effect, so only the
    pages with the "OE" callsigns are loaded: a binary search for the first of
    them (about 5 pages instead of all), then on until the callsigns pass
    "OE". Only Austrian callsigns ("OE" + digit) are stored. node_number is the
    EchoLink node, the same as trx.echolink_id."""
    pages = {}

    def page(offset):  # each page loaded once
        if offset not in pages:
            soup = get_soup(ECHOLINK_URL.format(offset))
            pages[offset] = soup, [tr for tr in soup.find_all("tr")
                                   if len(tr.find_all("td", recursive=False)) == len(ECHOLINK_COLUMNS)]
        return pages[offset]

    def first_call(rows):
        return rows[0].find("td").get_text(strip=True).upper() if rows else "~"  # empty page: past the end

    def last_call(rows):
        return rows[-1].find("td").get_text(strip=True).upper() if rows else "~"

    soup, rows = page(0)
    size = len(rows)
    if not size:
        raise ScrapError(f"{ECHOLINK_URL.format(0)}: no links found - did the page layout change?")
    last_offset = max((int(o) for o in re.findall(r"offset=(\d+)", str(soup))), default=0)

    # The last page that starts before "OE": the OE callsigns begin on it or right after.
    lo, hi = 0, last_offset // size
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if first_call(page(mid * size)[1]) < "OE":
            lo = mid
        else:
            hi = mid - 1
    found = []
    offset = lo * size
    while offset <= last_offset:
        rows = page(offset)[1]
        found += rows
        if last_call(rows) >= "OF":
            break
        offset += size

    def to_record(row):
        cells = row_cells(row, len(ECHOLINK_COLUMNS))
        if cells is None:
            return None
        record = dict(zip(ECHOLINK_COLUMNS, cells))
        record["callsign"] = base_callsign(record["station"])  # OE1XCS-R -> OE1XCS
        return record if re.match(r"OE\d", record["callsign"]) else None

    # About 20 Austrian links are online at any time: none means the search or
    # the page went wrong (save() refuses an empty list).
    return save("scrap_echolink", found, to_record)


# --- M17 -------------------------------------------------------------------

def scrap_m17_aut():
    """Stations linked to the M17 reflector M17-AUT (dashboard
    https://m17-aut.xreflector.net/, page "Links"; same layout as XLX905). Only
    Austrian callsigns ("OE" + digit) are stored: the reflector also links
    foreign repeaters (DB0MMR-R)."""
    url = "https://m17-aut.xreflector.net/index.php?show=links"

    def to_record(row):
        # 9 cells: #, Flag, DV Station ("OE5HOO-D"), Via, Last Heard,
        #          Linked for, Protocol, Module, IP
        cells = row_cells(row, 9)
        if cells is None:
            return None
        no, flag, dv_station, via, last_heard, linked_for, protocol, module, ip = cells
        call = base_callsign(dv_station)
        if not re.match(r"OE\d", call):
            return None
        return {"no": no, "flag": flag, "callsign": call, "dv_station": dv_station, "via": via,
                "last_heard": last_heard, "linked_for": linked_for, "protocol": protocol,
                "module": module, "ip_address": ip}

    soup = get_soup(url)
    header = soup.find("th", string=lambda t: t and t.strip() == "DV Station")
    if not header:
        raise ScrapError(f"{url}: no table with the header 'DV Station' found")
    rows = header.find_parent("table").find_all("tr")[1:]
    # save() refuses an empty list (layout changed?): no Austrian station
    # linked is normal here, so only store when there is one.
    records = [r for r in map(to_record, rows) if r]
    if not records:
        print(f"No Austrian station linked to M17-AUT ({len(rows)} stations linked).", flush=True)
        return 0
    return save("scrap_m17_aut", rows, to_record)


# --- HamnetDB ----------------------------------------------------------------

def scrap_hamnet_site():
    """The Austrian sites (callsign "OE" + digit, not deleted) registered at
    HamnetDB, from its JSON export of all sites (about 3700). Not a network:
    only whether a site is registered (api.site_type.hamnetdb). No history -
    each run replaces the table (the old list stays if this one fails)."""
    url = "https://hamnetdb.net/csv.cgi?tab=site&json=1"
    sites = fetch(url).json()
    if not isinstance(sites, list):
        raise ScrapError(f"{url}: no list of sites")

    def number(text):  # "48,337982" -> 48.337982
        try:
            return float(str(text).replace(",", "."))
        except ValueError:
            return None

    def to_record(site):
        call = callsign(site.get("callsign"))
        if not re.match(r"OE\d", call) or site.get("deleted"):
            return None
        return {"callsign": call, "hamnet_id": site.get("id"), "name": site.get("name"),
                "latitude": number(site.get("latitude")), "longitude": number(site.get("longitude")),
                "elevation": site.get("elevation"), "ground_asl": site.get("ground_asl"),
                "inactive": bool(site.get("inactive")), "maintainer": site.get("maintainer"),
                "edited": site.get("edited")}

    # save() refuses an empty list: about 190 Austrian sites are registered.
    return save("scrap_hamnet_site", sites, to_record, replace=True)


def scrap_dstar_ircddb():
    """Gateways of ircDDB in Austria. Each gateway is one <td width="119">:
      <a class="tooltip"><img src="/images/20green.png"><span>Online</span></a>
      <a class="tooltip" href="?AUT"><img src="/images/AUT.png">...</a>
      <a href="ircddb-log?30%200%20OE1XDS  ">OE1XDS  <span>Lastheard list ...</span></a>
    """
    url = "https://status.ircddb.net/cgi-bin/ircddb-gw?AUT"

    def to_record(cell):
        anchor = cell.find("a", href=lambda h: h and "ircddb-log" in h)
        if not anchor:
            return None  # not a gateway entry
        # The callsign is the anchor's own text, without the tooltip <span>.
        call = callsign("".join(anchor.find_all(string=True, recursive=False)))
        if not call:
            return None
        status_img = cell.find("img", src=lambda s: s and ("20green.png" in s or "20red.png" in s))
        status = "Online" if status_img and "20green.png" in status_img["src"] else "Offline"
        # The flag image is named after the ISO 3166 alpha-3 code; its alt text is empty.
        flag = cell.find("img", src=lambda s: s and re.search(r"/[A-Z]{3}\.png$", s))
        country = os.path.splitext(os.path.basename(flag["src"]))[0] if flag else ""
        return {"callsign": call, "status": status, "country": country}

    soup = get_soup(url)
    cells = [td for table in find_all(soup, url, "table", attrs={"bgcolor": "white"})
             for td in table.find_all("td", attrs={"width": "119"})]
    return save("scrap_dstar_ircddb", cells, to_record)


def scrap_dstar_ref096():
    """Stations linked to the D-Plus reflector REF096 (DREFD dashboard
    http://ref096.dstargateway.org/): a live view of the reflector's links, not
    a registry. Two tables:
      "Linked Gateways"  one column per reflector module (A-E); each cell is a
                         gateway with its own module, "OE6XDF B" = module B of
                         gateway OE6XDF linked to REF096 A. link_type 'gateway'.
      "Remote Users"     stations linked as users ("HotSpot"): repeaters with
                         MMDVM (OE7XLH) and personal hotspots, optionally with a
                         module ("OE6TXW D"); "Last TX on" is the reflector module
                         last transmitted on, or "listening". link_type 'mmdvm'.
    Stored as node "OE6XDF-B" (as on XLX905), so it matches trx.dstar_rpt1. The
    users' messages (names) and the last-heard list are not stored."""
    url = "http://ref096.dstargateway.org/"
    soup = get_soup(url)
    header = soup.find("th", string=lambda t: t and t.strip() == "Module A")
    if not header:
        raise ScrapError(f"{url}: no table 'Linked Gateways' (header 'Module A') found")
    table = header.find_parent("table")
    modules = [th.get_text(strip=True).replace("Module", "").strip() for th in header.find_parent("tr").find_all("th")]
    items = [("gateway", module, td.get_text(" ", strip=True))
             for tr in table.find_all("tr")[1:]
             for module, td in zip(modules, tr.find_all("td", recursive=False))]

    # Remote users: the table with the header "Type" (Callsign, User Message, Last TX on, Type).
    type_header = soup.find("th", string=lambda t: t and t.strip() == "Type")
    if not type_header:
        raise ScrapError(f"{url}: no table 'Remote Users' (header 'Type') found")
    for tr in type_header.find_parent("table").find_all("tr")[1:]:
        cells = [td.get_text(" ", strip=True) for td in tr.find_all("td", recursive=False)]
        if len(cells) >= 3:
            last_tx = cells[2] if re.fullmatch(r"[A-Z]", cells[2]) else ""  # else "listening"
            items.append(("mmdvm", last_tx, cells[0]))

    def to_record(item):
        link_type, reflector_module, text = item
        parts = text.split()
        if not parts:
            return None  # empty cell
        gateway_module = parts[1].upper() if len(parts) > 1 else ""
        call = callsign(parts[0])
        return {"callsign": call, "node": f"{call}-{gateway_module}" if gateway_module else call,
                "gateway_module": gateway_module, "reflector_module": reflector_module or None,
                "link_type": link_type}

    return save("scrap_dstar_ref096", items, to_record)


def scrap_dstar_ref():
    """Repeater list of dstarusers.org for country 10 (Austria)."""
    url = "https://dstarusers.org/repeaters.php"

    def to_record(row):
        # 7 cells: Callsign, City, State, 2m, 70cm, 23cm, 23cmDD
        cells = row_cells(row, 7)
        if cells is None or "Callsign" in cells[0]:
            return None  # header
        call, city, state, freq_2m, freq_70cm, freq_23cm, freq_23cmdd = cells
        return {"callsign": callsign(call), "city": city, "state": state, "freq_2m": freq_2m,
                "freq_70cm": freq_70cm, "freq_23cm": freq_23cm, "freq_23cmdd": freq_23cmdd}

    soup = get_soup(url, method="post", data={"countrylisting": "10", "criteriago": "Go"})
    rows = find_all(soup, url, "tr", class_=lambda c: c and c.startswith("rowres"))
    return save("scrap_dstar_ref", rows, to_record)


# --- TETRA -----------------------------------------------------------------

def scrap_tetra_oevsv():
    """Gateways of the SVXReflector "TETRA OE-MASTER" (dashboard
    http://tetra-reflector.dyndns.org/, which loads create_html.php). Its one
    table holds the connected gateways, then a last-heard log and position
    reports; only the gateways have monitored talkgroups ("[ 9 20 232 ]"), and
    only those are stored. Gateways are listed with suffix ("OE1XCS-T",
    "OE6XAG-R"); "callsign" has it without. The network address is not stored."""
    url = "http://tetra-reflector.dyndns.org/create_html.php"
    soup = get_soup(url)
    header = soup.find("th", string=lambda t: t and t.strip() == "Monitor TG")
    if not header:
        raise ScrapError(f"{url}: no gateway table (column 'Monitor TG') found")
    seen = set()

    def to_record(row):
        # 9 cells: Gateway, Comment, Connected since, Network address, state,
        #          TG, TX on, TX off, Monitor TG
        cells = [td.get_text(" ", strip=True) for td in row.find_all("td", recursive=False)]
        if len(cells) < 9:
            return None
        gateway, comment, connected_since, _address, _state, tg, _tx_on, _tx_off, monitor = cells[:9]
        # Some gateway cells carry a tooltip with the comment: "OE4KMU Tetra-OE4KMU".
        gateway = gateway.split(" ")[0]
        tgs = re.fullmatch(r"\[\s*([\d\s]*\d)\s*\]", monitor)
        if not tgs or gateway in seen:
            return None  # log / position row, or listed twice
        seen.add(gateway)
        return {"callsign": base_callsign(gateway), "node": gateway, "comment": comment,
                "connected_since": connected_since, "tg": tg, "monitored_tgs": " ".join(tgs.group(1).split())}

    return save("scrap_tetra_oevsv", header.find_parent("table").find_all("tr"), to_record)


def scrap_tetra_de():
    """Austrian nodes on the TETRA SVXReflectors shown by the "Tetra Dashboard"
    http://leipzig2000.dyndns.org:4047/ (a React page that loads the JSON
    /api/status). It merges several reflectors (DL, EA, CT - "sourceTag"),
    most nodes are not Austrian: only nodes with an OE callsign and monitored
    talkgroups are stored, the rest is dropped before storing. Nodes are keyed
    by callsign with suffix ("OE9XFV-R"); "callsign" has it without. Many nodes
    send the SVXLink default QTH (433.45 MHz, "My QTH Name", 60.12345/17.12345):
    only the transmitter frequency is stored, and not the default. Registered
    terminals, SDS positions and QSO members (personal data) are not stored."""
    url = "http://leipzig2000.dyndns.org:4047/api/status"
    try:
        nodes = fetch(url).json()["nodes"]
    except (ValueError, KeyError, TypeError) as e:
        raise ScrapError(f"{url}: no JSON with 'nodes' ({e})") from e
    if not isinstance(nodes, dict):
        raise ScrapError(f"{url}: 'nodes' is not an object")

    def to_record(item):
        node, info = item
        node = str(node).strip().upper()
        if not re.match(r"OE\d[A-Z]", node) or not isinstance(info, dict) or not info.get("monitoredTGs"):
            return None
        qth = (info.get("qth") or [{}])[0] or {}
        tx = next(iter((qth.get("tx") or {}).values()), {}) or {}
        tx_freq = str(tx.get("freq") or "").strip()
        location = str(info.get("nodeLocation") or "").strip()
        return {"callsign": base_callsign(node), "node": node,
                "monitored_tgs": " ".join(str(tg) for tg in info["monitoredTGs"]),
                "source_tag": str(info.get("sourceTag") or ""),
                "node_location": "" if location == "MyTownOrArea" else location,
                "tx_freq": "" if tx_freq == "433.45" else tx_freq}

    return save("scrap_tetra_de", nodes.items(), to_record)


# --- Winlink ---------------------------------------------------------------

def scrap_winlink_pactor():
    """Austrian (OE) Pactor gateways of Winlink. The page is an ASP.NET form:
    the first GET provides the view state for the POST that selects the mode."""
    url = "https://cms.winlink.org:444/GatewayChannels.aspx"
    session = requests.Session()
    form = get_soup(url, session=session)

    def hidden(name):
        field = form.find("input", {"name": name})
        return field["value"] if field else ""

    data = {name: hidden(name) for name in ("__VIEWSTATE", "__EVENTVALIDATION", "__VIEWSTATEGENERATOR")}
    data.update({"rblModes": "Pactor", "txtServiceCodes": "PUBLIC", "btnRefresh": "Refresh"})
    soup = get_soup(url, method="post", session=session, data=data)

    def to_record(row):
        cols = row.find_all("td")
        if len(cols) < 7:
            return None
        label = cols[1].find("label")
        call = callsign(label.get_text() if label else "")
        if not call.startswith("OE"):
            return None  # Austrian gateways only
        posted, grid_square, frequency, mode, hours, qth = (
            cols[i].get_text(strip=True) for i in (0, 2, 3, 4, 5, 6))
        return {"posted": posted, "callsign": call, "grid_square": grid_square,
                "frequency": frequency, "mode": mode, "hours": hours, "qth": qth}

    table = soup.find("table", {"id": "RmsChannelGrid"})
    if not table:
        raise ScrapError(f"{url}: table 'RmsChannelGrid' not found")
    return save("scrap_winlink_pactor", table.find_all("tr")[1:], to_record)  # skip the header


# All scrapers, by name (= table name), in the order scrap_all.py runs them.
SCRAPERS = {f.__name__: f for f in [
    scrap_c4fm_ycs232,
    scrap_dmr_ipsc2,
    scrap_dmr_ipsc2_de,
    scrap_dmr_ipsc2_hotspot,
    scrap_dmr_brandmeister,
    scrap_oelink,
    scrap_fm_svx_oe9,
    scrap_dstar_dcs009,
    scrap_dstar_xlx905,
    scrap_dstar_ircddb,
    scrap_dstar_ref096,
    scrap_dstar_ref,
    scrap_tetra_oevsv,
    scrap_tetra_de,
    scrap_m17_aut,
    scrap_echolink,
    scrap_hamnet_site,
    scrap_winlink_pactor,
]}
