# repeater-db
Database with REST API for Amateur Radio repeaters, digipeaters and beacons.

This repository is licensed under the Apache 2.0 license.

## Machine

Install Debian 11, add packages:
The code below might work well with other distributions and releases, but was only tested with Debian 11.
```
    apt install postgresql nginx postgis postgresql-13-postgis-3 git certbot python3-certbot-nginx
```

## Web server certificate
```
# create 'Let's encrypt' certificate for repeater.oevsv.at
certbot certonly
```
## Web server
```
# setup nginx
# add /etc/nginx/sites-available/repeater.oevsv.at
## create web root
mkdir /var/www/repeater.oevsv.at
```
## Database
Setup users, tables and add OpenData sources
### Setup database vhf
```
# Postgres
su postgres
psql
CREATE DATABASE vhf;
-- user and password to be replaced
create user username with encrypted password '***';
grant all privileges on database vhf to username;
quit
```
### Add Postgis extensions
```
psql vhf
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION postgis_raster;
quit
```

### Import schema
Note: vhf_schema.sql was generated using "pg_dump -s".
```
# Import schema
psql vhf < vhf_schema.sql
```

### Import Austrian terrain open data
This step might take a while to process.
```
# Import digital height model of Austria
# see https://www.data.gv.at/katalog/dataset/dgm
# available under CC BY 4.0 - geoland.at
wget "https://gis.ktn.gv.at/OGD/Geographie_Planung/ogd-10m-at.zip"
unzip ogd-10m-at.zip
# save space
rm ogd-10m-at.zip
# import - might take several hours
raster2pgsql -s 31287 -I -t 10x10 -M  dhm_at_lamb_10m_2018.tif dhm|psql vhf
psql
grant select on dhm to user;
exit
# check import
# Großglockner: 47.074531° N, 12.6939° E
psql vhf
SELECT ST_Value(rast,(ST_Transform(ST_SetSRID(ST_MakePoint(12.6939,47.074531),4326),31287)))
  FROM  dhm
  WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(12.6939,47.074531),4326),31287)));
```
### Import Austrian administrative borders open data
```
# Import administrative borders within Austria
# see https://www.data.gv.at/katalog/dataset/verwaltungsgrenzen-vgd-stichtagsdaten-grundstucksgenau
# available under CC BY 4.0 - BEV
wget https://nextcloud.bev.gv.at/nextcloud/index.php/s/GmLRRRfK6E8k79P/download/VGD-Oesterreich_gst_01.04.2021.zip
psql vhf
shp2pgsql -s 31287 -I  *.shp > vgd.sql
psql vhf -1 < vgd.sql
grant select on oesterreich_bev_vgd_lam to user;
exit
```

### Import sites
A site is defined as location with one or more callsigns and or transceivers.
```
# Import site table
psql vhf -1 < vhf_site.sql
```
### Import trx
Each active site contains one or more transmitters and receivers.

```
# Import site table
psql vhf -1 < vhf_trx.sql
```

## Setup postgrest
Postgrest is used to provide a REST interface to the database.
```
# setup /etc/postgrest/postgrest.conf
# test API
wget https://repeater.oevsv.at/api/site
wget https://repeater.oevsv.at/api/trx
# a more complex query
wget https://repeater.oevsv.at/api/trx?dmr=eq.true&band=eq.2m
```

