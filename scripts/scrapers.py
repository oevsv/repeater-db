"""The scraped sources: one function per scrap_* table (same name).

Each returns the number of rows inserted and raises on failure; see
scrap_common.py for the shared download / parse / store code and the callsign
rules, scrap_all.py to run them.
"""

import os
import re

import requests

from scrap_common import (ScrapError, base_callsign, callsign, fetch, find_all, get_soup, row_cells,
                          save, scrap_dmr_status_page, scrap_status_page)


# --- DMR -------------------------------------------------------------------

def scrap_dmr_ipsc2():
    return scrap_dmr_status_page("https://ipsc2.oevsv.at/_status.html", "scrap_dmr_ipsc2")


def scrap_dmr_ipsc2_hotspot():
    return scrap_dmr_status_page("https://dmo.oevsv.at/_status.html", "scrap_dmr_ipsc2_hotspot")


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
    scrap_dmr_ipsc2_hotspot,
    scrap_oelink,
    scrap_fm_svx_oe9,
    scrap_dstar_dcs009,
    scrap_dstar_xlx905,
    scrap_dstar_ircddb,
    scrap_dstar_ref,
    scrap_winlink_pactor,
]}
