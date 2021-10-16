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


