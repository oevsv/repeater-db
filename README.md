# repeater-db
Database for repeaters and beacons

# Machine
Install Debian 11, add packages:
apt install postgresql nginx postgis postgresql-13-postgis-3 git certbot python3-certbot-nginx

# create 'Let's encrypt' certificate for repeater.oevsv.at
certbot certonly

# setup nginx
# add /etc/nginx/sites-available/repeater.oevsv.at
# create web root
mkdir /var/www/repeater.oevsv.at

# Postgres
su postgres
psql
CREATE DATABASE vhf;
-- user and password to be replaced
create user username with encrypted password '***';
grant all privileges on database vhf to username;
quit
psql vhf
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION postgis_raster;
quit
# Import digital height modell of Austria
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
# Import administrative borders within Austria
# see https://www.data.gv.at/katalog/dataset/verwaltungsgrenzen-vgd-stichtagsdaten-grundstucksgenau
# available under CC BY 4.0 - BEV
wget https://nextcloud.bev.gv.at/nextcloud/index.php/s/GmLRRRfK6E8k79P/download/VGD-Oesterreich_gst_01.04.2021.zip
psql vhf
shp2pgsql -s 31287 -I  *.shp > vgd.sql
psql vhf -1 < vgd.sql
grant select on oesterreich_bev_vgd_lam to user;
exit

# Import trigger (sets geom, see level and geo_prefix)
psql vhf -1 < vhf_trigger_repeater.sql
# Import repeater table
psql vhf -1 < vhf_repeater.sql
# Import licenses table
psql vhf -1 < vhf_licenses.sql


