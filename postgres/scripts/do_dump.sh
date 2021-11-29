#!/bin/bash
# dump key tables from vhf database

set -x 
export LANG=C

pg_dump vhf -t trx > vhf_trx.sql

pg_dump vhf -t site > vhf_site.sql
