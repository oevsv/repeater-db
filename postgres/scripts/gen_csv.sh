#!/bin/bash
# oe3dzw, 2021-11-28


# export view

# Chirp format 
echo "COPY (select * from chirp_fm) TO '/var/www/repeater.oevsv.at/static/csv/chirp_fm.csv.tmp' CSV HEADER DELIMITER ',';" | psql -q vhf
# remove quotes
sed -i "s/\"//g" /var/www/repeater.oevsv.at/static/csv/chirp_fm.csv.tmp
# atomic replacement of previous file
mv /var/www/repeater.oevsv.at/static/csv/chirp_fm.csv.tmp /var/www/repeater.oevsv.at/static/csv/chirp_fm.csv


# RT-Systems 

# IC-9700 format 
# Dstar
echo "COPY (select * from rt_ic9700_dstar) TO '/var/www/repeater.oevsv.at/static/csv/rt_ic9700_dstar.csv.tmp' CSV HEADER DELIMITER ',';" | psql -q vhf
# remove dummy
sed -i "s/Dummy//g" /var/www/repeater.oevsv.at/static/csv/rt_ic9700_dstar.csv.tmp
# remove quotes
sed -i "s/\"//g" /var/www/repeater.oevsv.at/static/csv/rt_ic9700_dstar.csv.tmp
# atomic replacement of previous file
mv /var/www/repeater.oevsv.at/static/csv/rt_ic9700_dstar.csv.tmp /var/www/repeater.oevsv.at/static/csv/rt_ic9700_dstar.csv

# FM
echo "COPY (select * from rt_ic9700_fm) TO '/var/www/repeater.oevsv.at/static/csv/rt_ic9700_fm.csv.tmp' CSV HEADER DELIMITER ',';" | psql -q vhf
# remove dummy
sed -i "s/Dummy//g" /var/www/repeater.oevsv.at/static/csv/rt_ic9700_fm.csv.tmp
# remove quotes
sed -i "s/\"//g" /var/www/repeater.oevsv.at/static/csv/rt_ic9700_fm.csv.tmp
# atomic replacement of previous file
mv /var/www/repeater.oevsv.at/static/csv/rt_ic9700_fm.csv.tmp /var/www/repeater.oevsv.at/static/csv/rt_ic9700_fm.csv





# Radioddity GD77 format 
echo "COPY (select * from gd77) TO '/var/www/repeater.oevsv.at/static/csv/gd77.csv.tmp' CSV HEADER DELIMITER ',';" | psql -q vhf
# remove quotes
sed -i "s/\"//g" /var/www/repeater.oevsv.at/static/csv/gd77.csv.tmp
# atomic replacement of previous file
mv /var/www/repeater.oevsv.at/static/csv/gd77.csv.tmp /var/www/repeater.oevsv.at/static/csv/gd77.csv
