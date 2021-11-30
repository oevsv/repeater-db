#!/bin/bash
# dump key tables from vhf database

set -x 
export LANG=C

pg_dump vhf -s  > vhf_schema.sql
pg_dump vhf -t trx > vhf_trx.sql
pg_dump vhf -t site > vhf_site.sql
pg_dump vhf -t bl_kz_prefix > bl_kz_prefix.sql
pg_dump vhf -t site > vhf_site.sql
pg_dump vhf -t site > vhf_site.sql
pg_dump vhf -t site > vhf_site.sql
pg_dump vhf -t bands > vhf_bands.sql

