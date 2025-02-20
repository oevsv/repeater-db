from load_db_config import load_db_config
from scrap_c4fm_ycs232 import *
from scrap_dmr_ipsc2 import *
from scrap_dmr_ipsc2_hotspot import *
from scrap_dstar_dcs009 import *
from scrap_dstar_ircddb import *
from scrap_dstar_ref import *
from scrap_dstar_xlx905 import *
from scrap_oelink import *


def scrap_all():
    # Assume each function returns 0 on success and non-zero on failure
    status_c4fm_ycs232 = scrap_c4fm_ycs232()
    status_dmr_ipsc2 = scrap_dmr_ipsc2()
    status_dmr_ipsc2_hotspot = scrap_dmr_ipsc2_hotspot()
    status_dstar_dcs009 = scrap_dstar_dcs009()
    status_dstar_ircddb = scrap_dstar_ircddb()
    status_dstar_ref = scrap_dstar_ref()
    status_dstar_xlx905 = scrap_dstar_xlx905()
    status_oelink = scrap_oelink()

    # Accumulate
    statuses = [
        status_c4fm_ycs232,
        status_dmr_ipsc2,
        status_dmr_ipsc2_hotspot,
        status_dstar_dcs009,
        status_dstar_ircddb,
        status_dstar_ref,
        status_dstar_xlx905,
        status_oelink
    ]

    # Check if any status code is non-zero
    if any(status != 0 for status in statuses):
        return -1

    return 0


# only execute main if not imported
if __name__ == "__main__":
    scrap_all()