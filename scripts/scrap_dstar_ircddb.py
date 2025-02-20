#!/usr/bin/python3

# scraps Austrian Dstar ircddb stations

import requests
import psycopg2
from bs4 import BeautifulSoup
from psycopg2 import sql
from datetime import datetime
from load_db_config import load_db_config


def scrap_dstar_ircddb():
    url = "https://status.ircddb.net/cgi-bin/ircddb-gw?AUT"
    headers = {"User-Agent": "Mozilla/5.0"}

    # 1) Make GET request to the page
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "html.parser")

    # 2) Find all <table> elements with BGCOLOR='white'
    data_tables = soup.find_all("table", attrs={"bgcolor": "white"})
    if not data_tables:
        print("No table with BGCOLOR='white' found. Exiting.")
        return

    # Prepare for database inserts
    records = []
    now_utc = datetime.utcnow()

    for table in data_tables:
        # Each <tr> might contain multiple <td> with width=119
        # Each <td> is one gateway
        cells = table.find_all("td", attrs={"width": "119"})
        for cell in cells:
            # Determine Online/Offline by the first <img>
            status_img = cell.find("img", src=lambda s: s and ("20green.png" in s or "20red.png" in s))
            status = "Offline"
            if status_img and "20green.png" in status_img["src"]:
                status = "Online"

            # The second <img> is typically the flag alt (e.g. "Austria", "Germany", etc.)
            flag_imgs = cell.find_all("img")
            country = ""
            if len(flag_imgs) >= 2:
                country = flag_imgs[1].get("alt", "").strip()

            # The callsign link references "ircddb-log". It usually contains two parts:
            #  • The callsign text (e.g. "OE1XDS")
            #  • A <span> with text "Lastheard list OE1XDS"
            anchor = cell.find("a", href=lambda t: t and "ircddb-log" in t)
            if not anchor:
                # Not a valid gateway entry
                continue

            # Extract the callsign from the anchor's contents
            # Usually the anchor looks like: "OE1XDS  <span>Lastheard list OE1XDS</span>"
            # We can separate them by looking at the anchor's immediate text vs. the span text.
            span = anchor.find("span")
            if span:
               # The main callsign is often the text node before the span
                anchor_text_parts = anchor.contents
                # anchor.contents might be something like ["OE1XDS  ", <span>...</span>]
                callsign_raw = ""
                for part in anchor_text_parts:
                    if part.name == "span":
                        # This is the <span> we already captured
                        continue
                    elif isinstance(part, str):
                        # This is a text piece
                        callsign_raw += part.strip()

                callsign = callsign_raw.strip()
            else:
                # If there's no span, maybe the entire anchor text is a callsign
                callsign = anchor.get_text(strip=True)
                last_heard_text = ""

            if callsign:
                records.append((callsign, status, country, now_utc))

    # 3) Insert into PostgreSQL
    db_params = load_db_config('db_config.ini', 'postgresql')
    conn = psycopg2.connect(**db_params)

    try:
        with conn:
            with conn.cursor() as cur:
                insert_sql = sql.SQL("""
                INSERT INTO scrap_dstar_ircddb
                   (callsign, status, country, scraped_timestamp)
                VALUES (%s, %s, %s, %s)
                """)
                cur.executemany(insert_sql, records)
                print(f"Inserted {cur.rowcount} rows into scrap_dstar_ircddb.")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


# only execute main if not imported
if __name__ == "__main__":
    scrap_dstar_ircddb()
