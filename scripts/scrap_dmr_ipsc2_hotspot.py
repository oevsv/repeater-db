#!/usr/bin/python3

# scraps Austrian DMR IPSC2 Hotspot stations

import requests
from bs4 import BeautifulSoup
import psycopg2
from psycopg2 import sql
from datetime import datetime
from configparser import ConfigParser


def load_db_config(filename='db_config.ini', section='postgresql'):
    """
    Load database configuration from an .ini file.
    Returns a dictionary of parameters for psycopg2.
    """
    # example 'db_config.ini'
    # [postgresql]
    # host = 1.2.3.4
    # port = 5432
    # database = vhf
    # user = add-user-here
    # password = add-password-here

    parser = ConfigParser()
    parser.read(filename)

    if not parser.has_section(section):
        raise Exception(f"Section {section} not found in the {filename} file.")

    db_config = {}
    for param in parser.items(section):
        db_config[param[0]] = param[1]

    return db_config


def main():
    # 1. Make GET request to the desired URL
    url = "https://dmo.oevsv.at/_status.html"
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise an error if request fails

    # 2. Parse the HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # Find all rows (tr) with class="trow" — these should hold the data we want
    rows = soup.find_all("tr", class_="trow")
    if not rows:
        print("No rows found with class='trow'. Exiting.")
        return

    records = []
    now_utc = datetime.utcnow()

    for row in rows:
        # Each row should contain 12 cells in this order:
        #   0=NR, 1=REPEATER, 2=INFO, 3=ID, 4=TS1, 5=CQ, 6=TS1-INFO,
        #   7=TS2, 8=TS2-INFO, 9=REF, 10=START, 11=HARDWARE
        columns = row.find_all("td")
        if len(columns) < 12:
            continue  # skip rows that don't match this pattern

        nr = columns[0].get_text(strip=True)
        repeater = columns[1].get_text(strip=True)
        info = columns[2].get_text(strip=True)
        repeater_id = columns[3].get_text(strip=True)
        ts1 = columns[4].get_text(strip=True)
        cq = columns[5].get_text(strip=True)
        ts1_info = columns[6].get_text(strip=True)
        ts2 = columns[7].get_text(strip=True)
        ts2_info = columns[8].get_text(strip=True)
        ref = columns[9].get_text(strip=True)
        start = columns[10].get_text(strip=True)
        hardware = columns[11].get_text(strip=True)

        records.append((
            nr, repeater, info, repeater_id, ts1, cq, ts1_info,
            ts2, ts2_info, ref, start, hardware, now_utc
        ))

    # 3. Insert records into PostgreSQL
    db_params = load_db_config(filename='db_config.ini', section='postgresql')
    conn = psycopg2.connect(**db_params)

    try:
        with conn:
            with conn.cursor() as cur:
                insert_query = sql.SQL("""
                    INSERT INTO scrap_dmr_ipsc2_hotspot
                    (
                        nr, 
                        repeater, 
                        info, 
                        repeater_id, 
                        ts1, 
                        cq, 
                        ts1_info, 
                        ts2, 
                        ts2_info, 
                        ref, 
                        start, 
                        hardware,
                        scraped_timestamp
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """)
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into scrap_dmr_ipsc2_hotspot.")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


# only execute main if not imported
if __name__ == "__main__":
    main()
