#!/usr/bin/python3

# scraps Austrian C4FM YCS232 stations

import requests
from bs4 import BeautifulSoup
import psycopg2
from psycopg2 import sql
from datetime import datetime
from load_db_config import load_db_config


def main():
    # 1. Make GET request to the desired URL
    url = "https://ycs232.oevsv.at/_status.html"
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise an error if the request fails

    # 2. Parse the HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # Find all rows (tr) with class="trow"
    rows = soup.find_all("tr", class_="trow")
    if not rows:
        print("No rows found with class='trow'. Exiting.")
        return

    records = []
    now_utc = datetime.utcnow()

    for row in rows:
        columns = row.find_all("td")
        # We expect 10 columns:
        #   0=Nr, 1=Repeater (with callsign/group), 2=Name, 3=QRG, 4=ID, 5=DG-ID,
        #   6=NAME2, 7=RX/TX, 8=MODE, 9=TYPE
        if len(columns) < 10:
            continue

        nr = columns[0].get_text(strip=True)

        # Separate callsign from group_code for column[1].
        # e.g. "OE1GPA     (05)" => callsign="OE1GPA" and group_code="05"
        repeater_full_text = columns[1].get_text(strip=True)
        if '(' in repeater_full_text:
            # Split around the last '(' so we keep the entire callsign even if
            # it has spaces
            parts = repeater_full_text.rsplit('(', 1)
            callsign = parts[0].strip()
            group_code = parts[1].replace(')', '').strip()
        else:
            callsign = repeater_full_text
            group_code = ""

        name = columns[2].get_text(strip=True)
        qrg = columns[3].get_text(strip=True)
        repeater_id = columns[4].get_text(strip=True)
        dg_id = columns[5].get_text(strip=True)
        name2 = columns[6].get_text(strip=True)
        rx_tx = columns[7].get_text(strip=True)
        mode = columns[8].get_text(strip=True)
        type_ = columns[9].get_text(strip=True)

        records.append((
            nr, callsign, group_code, name, qrg,
            repeater_id, dg_id, name2, rx_tx, mode, type_, now_utc
        ))

    # 3. Insert records into PostgreSQL
    db_params = load_db_config(filename='db_config.ini', section='postgresql')
    conn = psycopg2.connect(**db_params)

    try:
        with conn:
            with conn.cursor() as cur:
                insert_query = sql.SQL("""
                    INSERT INTO scrap_c4fm_ycs232
                    (
                        nr,
                        callsign,
                        group_code,
                        name,
                        qrg,
                        repeater_id,
                        dg_id,
                        name2,
                        rx_tx,
                        mode,
                        type,
                        scraped_timestamp
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """)
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into scrap_c4fm_ycs232.")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


# only execute main if not imported
if __name__ == "__main__":
    main()
