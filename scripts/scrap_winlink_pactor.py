#!/usr/bin/python3

import re
import requests
from bs4 import BeautifulSoup
import psycopg2
from psycopg2 import sql
from datetime import datetime
from html import unescape
from load_db_config import load_db_config

def scrap_winlink_pactor():
    # 1. Initial GET to retrieve viewstate and eventvalidation
    session = requests.Session()
    url = "https://cms.winlink.org:444/GatewayChannels.aspx"
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
    }

    try:
        response = session.get(url, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Failed to retrieve initial page: {e}")
        return

    soup = BeautifulSoup(response.text, 'html.parser')

    # Extract necessary hidden fields
    viewstate = soup.find('input', {'name': '__VIEWSTATE'})
    viewstate = viewstate['value'] if viewstate else ''
    eventvalidation = soup.find('input', {'name': '__EVENTVALIDATION'})
    eventvalidation = eventvalidation['value'] if eventvalidation else ''
    viewstategenerator = soup.find('input', {'name': '__VIEWSTATEGENERATOR'})
    viewstategenerator = viewstategenerator['value'] if viewstategenerator else ''

    # 2. Prepare POST data with default mode (Pactor) and service code (PUBLIC)
    data = {
        '__VIEWSTATE': viewstate,
        '__EVENTVALIDATION': eventvalidation,
        '__VIEWSTATEGENERATOR': viewstategenerator,
        'rblModes': 'Pactor',
        'txtServiceCodes': 'PUBLIC',
        'btnRefresh': 'Refresh'
    }

    try:
        response = session.post(url, headers=headers, data=data)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Failed to submit POST request: {e}")
        return

    # 3. Parse the response HTML for the data table
    soup = BeautifulSoup(response.text, 'html.parser')
    table = soup.find('table', {'id': 'RmsChannelGrid'})
    if not table:
        print("Data table 'RmsChannelGrid' not found.")
        return

    rows = table.find_all('tr')[1:]  # Skip the header row
    records = []
    timestamp_now = datetime.utcnow()

    for row in rows:
        cols = row.find_all('td')
        if len(cols) < 7:
            continue  # Skip rows that don't have enough columns

        posted = cols[0].get_text(strip=True)
        callsign_label = cols[1].find('label')
        callsign = callsign_label.get_text(strip=True) if callsign_label else ''

        # Filter for callsigns starting with OE
        if not callsign.startswith('OE'):
            continue

        grid_square = cols[2].get_text(strip=True)
        frequency = cols[3].get_text(strip=True)
        mode = cols[4].get_text(strip=True)
        hours = cols[5].get_text(strip=True)
        qth = cols[6].get_text(strip=True)

        # Extract contact info from onmouseover attribute
        contact_name = ''
        contact_email = ''
        contact_address = ''
        contact_phone = ''

        if callsign_label and callsign_label.has_attr('onmouseover'):
            onmouseover = callsign_label['onmouseover']
            # Use regex to extract the HTML content from DisplayTip
            match = re.search(r'DisplayTip\(.*?,\s*"(.*?)"\)', onmouseover)
            if match:
                html_content = unescape(match.group(1))
                inner_soup = BeautifulSoup(html_content, 'html.parser')
                inner_table = inner_soup.find('table')
                if inner_table:
                    inner_rows = inner_table.find_all('tr')
                    if len(inner_rows) >= 5:
                        # Name from second row (index 1)
                        name_td = inner_rows[1].td
                        contact_name = name_td.get_text(strip=True) if name_td else ''
                        # Email from third row (index 2)
                        email_td = inner_rows[2].td
                        contact_email = email_td.get_text(strip=True) if email_td else ''
                        # Address from fourth row (index 3)
                        address_td = inner_rows[3].td
                        if address_td:
                            address_parts = [part.strip() for part in address_td.stripped_strings]
                            contact_address = ', '.join(filter(None, address_parts))
                        # Phone from fifth row (index 4)
                        phone_td = inner_rows[4].td
                        contact_phone = phone_td.get_text(strip=True) if phone_td else ''

        # Prepare the record tuple
        records.append((
            posted, callsign, grid_square, frequency, mode, hours, qth,
            contact_name, contact_email, contact_address, contact_phone,
            timestamp_now
        ))

    # 4. Insert data into PostgreSQL database
    db_params = load_db_config(filename='db_config.ini')
    try:
        connection = psycopg2.connect(**db_params)
    except psycopg2.OperationalError as e:
        print(f"Failed to connect to database: {e}")
        return

    try:
        with connection:
            with connection.cursor() as cur:
                insert_query = sql.SQL("""
                    INSERT INTO scrap_winlink_pactor
                    (posted, callsign, grid_square, frequency, mode, hours, qth,
                     contact_name, contact_email, contact_address, contact_phone,
                     scraped_timestamp)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """)
                cur.executemany(insert_query, records)
                print(f"Inserted {cur.rowcount} rows into scrap_winlink_gateways table.")
    except Exception as e:
        print(f"Error inserting data into database: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    scrap_winlink_pactor()