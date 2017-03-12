from sqlalchemy import create_engine as ce
import itertools as it
import csv
from numpy import linspace
from openpyxl import load_workbook
 

FRCSDIR = 'FRCS'

dbname = 'apl_cec'
host = 'switch-db2.erg.berkeley.edu'
user = 'ptittmann'

def dbconfig(name, echoCmd=True):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    #conString = '//username:{pwd}@{host}:{name}
    engine = ce('postgresql:///{0}'.format(name), echo=echoCmd)
    return engine


def iterHarvestSystems(output='frcs_batch.xlsx', intervals = 20, maxAYD=2500, minAYD=0):
    wb2 = load_workbook(FRCSDIR+'/'+output)
    print wb2.get_sheet_names()

    tpa = linspace(20,500,intervals)
    cuFt = 65.44 # select min(35.3147*450/("D_CONBM_kg"/"relNO")), max(35.3147*450/("D_CONBM_kg"/"relNO")), avg(35.3147*450/("D_CONBM_kg"/"relNO")), stddev(35.3147*450/("D_CONBM_kg"/"relNO")) from priority_areas where "relNO">0 and "D_CONBM_kg">0;
    resFrac = 0.8
    slp = linspace(0, 100, intervals)
    ayd = linspace(minAYD, maxAYD, intervals)
    trtArea = linspace(1, 20, intervals)
    elev = [0]
    comb = [['Stand',
             'State',
             'Slope',
             'AYD',
             'TreatmentArea',
             'Elev',
             'Harvesting System',
             'CT/ac',
             'CT residue fraction',
             'ft3/CT']]

    for idx, itm in enumerate(it.product(slp, ayd, trtArea, elev, tpa)):
        if itm[0] <= 50:
            comb.append([idx,
                         'CA',
                         itm[0],
                         itm[1],
                         itm[2],
                         itm[3],
                         'Ground-Based Mech WT',
                         int(itm[4]),
                         resFrac,
                         cuFt]
                        )
        else:
            comb.append([idx,
                         'CA',
                         itm[0],
                         itm[1],
                         itm[2],
                         itm[3],
                         'Cable Manual WT',
                         int(itm[4]),
                         resFrac,
                         cuFt])

    with open(FRCSDIR+'/'+output, "wb") as f:
        writer = csv.writer(f)
        writer.writerows(comb)
