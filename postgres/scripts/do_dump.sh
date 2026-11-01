#!/bin/bash
# dump key tables from vhf database
#
# vhf_schema.sql holds the complete schema; the table dumps hold data only, so
# they load on top of it without "already exists" errors. --disable-triggers
# keeps the trigger on site from recomputing sea level / region during a
# restore (that needs the terrain and border open data, see README), so the
# stored values are restored as they are. Restoring therefore needs a superuser.

set -x
export LANG=C

pg_dump vhf -s  > vhf_schema.sql
pg_dump vhf --data-only --disable-triggers -t site > vhf_site.sql
pg_dump vhf --data-only --disable-triggers -t trx > vhf_trx.sql
pg_dump vhf --data-only --disable-triggers -t bl_kz_prefix > bl_kz_prefix.sql
pg_dump vhf --data-only --disable-triggers -t bands > vhf_bands.sql
pg_dump vhf --data-only --disable-triggers -t direct_channels > vhf_direct_channels.sql
pg_dump vhf --data-only --disable-triggers -t setting_options > vhf_setting_options.sql
