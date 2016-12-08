from sqlalchemy import create_engine as ce
import itertools as it
import csv

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


def iterHarvestSystems(output='frcs_batch.csv', maxAYD=2500, minAYD=0):
    slp = range(0, 100, 5)
    ayd = range(minAYD, maxAYD, 100)
    trtArea = range(20, 200, 10)
    elev = [0]
    comb = [['Stand',
             'State',
             'Slope',
             'AYD',
             'Treatment Area',
             'Elev',
             'Harvesting System']]

    for idx, itm in enumerate(it.product(slp, ayd, trtArea, elev)):
        if itm[0] <= 50:
            comb.append([idx,
                         'CA',
                         itm[0],
                         itm[1],
                         itm[2],
                         itm[3],
                         'Ground-Based Mech WT'])
        else:
            comb.append([idx,
                         'CA',
                         itm[0],
                         itm[1],
                         itm[2],
                         itm[3],
                         'Cable Manual WT'])

    with open(FRCSDIR+'/'+output, "wb") as f:
        writer = csv.writer(f)
        writer.writerows(comb)
