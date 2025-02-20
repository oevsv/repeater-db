#!/usr/bin/python3

# scraps Austrian Dstar DCS009 stations

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
    url = "https://xlx232.oevsv.at/_status.html"
    headers = {
        "User-Agent": "Mozilla/5.0"
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise an error if request fails

    # 2) Parse the HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # Find all rows (tr) with class="trow" — these should hold the data we want
    rows = soup.find_all("tr", class_="trow")
    if not rows:
        print("No rows found with class='trow'. Exiting.")
        return

    records = []
    now_utc = datetime.utcnow()

    for row in rows:
        # Each row should contain 8 cells in this order:
        #  0=Nr, 1=DV Station, 2=Band, 3=Linked, 4=DCS GROUP, 5=via, 6=Software, 7=HB-Timer
        columns = row.find_all("td")
        if len(columns) < 8:
            # Not a valid data row
            continue

        # Extract column text
        nr = columns[0].get_text(strip=True)
        dv_station = columns[1].get_text(strip=True)
        band = columns[2].get_text(strip=True)
        linked = columns[3].get_text(strip=True)
        dcs_group = columns[4].get_text(strip=True)
        via = columns[5].get_text(strip=True)
        software = columns[6].get_text(strip=True)
        hb_timer = columns[7].get_text(strip=True)

        records.append((nr, dv_station, band, linked, dcs_group, via, software, hb_timer, now_utc))

    # 3. Insert the record set into PostgreSQL
    db_params = load_db_config(filename='db_config.ini', section='postgresql')
    conn = psycopg2.connect(**db_params)

    try:
        with conn:
            with conn.cursor() as cur:
                insert_query = sql.SQL("""
                    INSERT INTO scrap_dstar_dcs009
                        (nr, dv_station, band, linked, dcs_group, via, software, hb_timer, scraped_timestamp)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """)
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into dstar_dcs009.")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


# only execute main if not imported
if __name__ == "__main__":
    main()
