#!/usr/bin/python3

# scraps Austrian Dstar XLX905 stations

import requests
from bs4 import BeautifulSoup
import psycopg2
from psycopg2 import sql
from datetime import datetime
from configparser import ConfigParser


# -- SQL code to create the “dstar_xlx905” table in the PostgreSQL database
#
# CREATE TABLE dstar_dcs009 (
# id SERIAL PRIMARY KEY,
# nr TEXT,
# dv_station TEXT,
# band TEXT,
# linked TEXT,
# dcs_group TEXT,
# via TEXT,
# software TEXT,
# hb_timer TEXT,
# scraped_timestamp TIMESTAMP NOT NULL
# );

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
    # 1. Make the POST request to dstarusers.org
    # server does not support https
    url = "url = http://xlx905.oevsv.at:8888/index.php?show=repeaters"
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0 Safari/7.36"
    }

    response = requests.post(url, headers=headers)
    response.raise_for_status()  # Raise an error if the requestfailed

    # 2. Use BeautifulSoup to parse the returned HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # The repeaters are in a table with rows that have classes rowres1 or rowres2.
    rows = soup.find_all("tr", class_=lambda c: c and c.startswith("rowres"))

    # Prepare a list to hold all the scraped data
    records = []
    timestamp_now = datetime.utcnow()  # or datetime.now() if you prefer local time

    for row in rows:
        columns = row.find_all("td")
        if len(columns) < 7:
            # Not a valid data row
            continue

        # Skip the table header row
        if "Callsign" in columns[0].get_text():
            continue

        # Extract each column
        callsign = columns[0].get_text(strip=True)  # Callsign
        city = columns[1].get_text(strip=True)  # City
        state = columns[2].get_text(strip=True)  # State
        freq_2m = columns[3].get_text(strip=True)  # 2m
        freq_70cm = columns[4].get_text(strip=True)  # 70cm
        freq_23cm = columns[5].get_text(strip=True)  # 23cm
        freq_23cmdd = columns[6].get_text(strip=True)  # 23cmDD

        records.append((callsign, city, state, freq_2m, freq_70cm, freq_23cm, freq_23cmdd, timestamp_now))

    print(records)

    # 3. Insert results into PostgreSQL using credentials in db_config.ini
    db_params = load_db_config(filename='db_config.ini')
    connection = psycopg2.connect(**db_params)


    try:
        with connection:
            with connection.cursor() as cur:
                # Construct the INSERT statement. We’ll use %s placeholders for the prepared statement.
                insert_query = sql.SQL("""
                    INSERT INTO dstar_ref
                    (callsign, city, state, freq_2m, freq_70cm, freq_23cm, freq_23cmdd, scraped_timestamp)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """)

                # Execute the insert for all rows. executemany is a convenient approach.
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into dstar_ref table.")
    except Exception as e:
        print(f"Error inserting data into database: {e}")
    finally:
        connection.close()


# only execute main if not imported
if __name__ == "__main__":
    main()