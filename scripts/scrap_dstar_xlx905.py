#!/usr/bin/python3

# scraps Austrian Dstar XLX905 stations

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
    url = "http://xlx905.oevsv.at:8888/index.php?show=repeaters"
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    # 2. Parse the HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # The table we want has class="listingtable". Each row after the header
    # is a <tr>. We’ll skip the first two <tr> (they're the headings), then parse the rest.
    table = soup.find("table", class_="listingtable")
    if not table:
        print("Could not find table with class='listingtable'. Exiting.")
        return

    rows = table.find_all("tr")
    if len(rows) < 2:
        print("No data rows found in the table. Exiting.")
        return

    # The first row is a header row. The second row might also be a header
    # with input forms. We need to skip until we hit actual data rows.
    # Based on the sample HTML, data rows start from the row after the second header row.
    data_rows = rows[2:]  # Skip the first two rows (the <tr> for the table heading)

    records = []
    now_utc = datetime.utcnow()

    for row in data_rows:
        columns = row.find_all("td")
        # We expect 9 columns:
        #   0=#, 1=Flag, 2=DV Station, 3=Band, 4=Last Heard,
        #   5=Linked for, 6=Protocol, 7=Module, 8=IP
        if len(columns) < 9:
            # Possibly an empty row or something that doesn't match
            continue

        no_         = columns[0].get_text(strip=True)
        flag        = columns[1].get_text(strip=True)
        dv_station  = columns[2].get_text(strip=True)
        band        = columns[3].get_text(strip=True)
        last_heard  = columns[4].get_text(strip=True)
        linked_for  = columns[5].get_text(strip=True)
        protocol    = columns[6].get_text(strip=True)
        module      = columns[7].get_text(strip=True)
        ip_address  = columns[8].get_text(strip=True)

        records.append((
            no_, flag, dv_station, band, last_heard, linked_for,
            protocol, module, ip_address, now_utc
        ))

    # 3. Insert records into PostgreSQL
    db_params = load_db_config(filename='db_config.ini', section='postgresql')
    conn = psycopg2.connect(**db_params)

    try:
        with conn:
            with conn.cursor() as cur:
                insert_query = sql.SQL("""
                    INSERT INTO scrap_dstar_xlx905
                    (
                        no,
                        flag,
                        dv_station,
                        band,
                        last_heard,
                        linked_for,
                        protocol,
                        module,
                        ip_address,
                        scraped_timestamp
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """)
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into scrap_dstar_xlx905.")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


# only execute main if not imported
if __name__ == "__main__":
    main()