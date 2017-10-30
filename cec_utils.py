from sqlalchemy import create_engine
import itertools as it
from numpy import linspace, ceil, append
import pandas as pd
import xlwings as xlw
import tempfile as tf
import shutil, os, sys
#import sqlite3

FRCSDIR = 'FRCS'
inputFile = 'FRCS_TestDataOffset.xlsx'
sheetName = 'Input'
frcsModel = "FRCS-West.xls"
batchLoadMacro = "Module1.LoadDataFromXLSX"
batchPrcMacro = "Sheet32.Process_Batch_Click"

dbname = 'apl_cec'
user = 'jdlara'
passwd = 'Amadeus-2010'

colIndex = {'A': 'Stand',
            'B': 'State',
            'C': 'Slope',
            'D': 'AYD',
            'E': 'Treatment Area',
            'F': 'Elev',
            'G': 'System',
            'H': 'CT/ac',
            'I': 'CT residue fraction',
            'J': 'ft3/CT',
            'K': 'lb/ft3 CT',
            'L': 'CT hardwood fraction',
            'M': 'ST/ac',
            'N': 'ST residue fraction',
            'O': 'ft3/ST',
            'P': 'lb/ft3 ST',
            'Q': 'ST hardwood fraction',
            'R': 'LT/ac',
            'S': 'LT residue fraction',
            'T': 'ft3/LT',
            'U': 'lb/ft3 LT',
            'V': 'LT hardwood fraction',
            'W': 'Include move-in cost?',
            'X': 'Move-in miles',
            'Y': 'Collect & chip residues?',
            'Z': 'Partial cut?',
            'AA': 'Include loading costs?'}

def dbconfig(user,passwd,dbname, echo_i=False):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    str1 = ('postgresql+pg8000://' + user +':' + passwd + '@switch-db2.erg.berkeley.edu:5433/' 
            + dbname + '?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory')
    engine = create_engine(str1,echo=echo_i)
    return engine

def iterateVariables(intervals=40, maxAYD=5280, minAYD=0, state='CA',std_name = 'frcs_batch_'):
    """
    Returns a pandas dataframe with the combinatorial
    product of all input theoretical input variables
    Doesn't work, not in use
    """
    tpa = range(20, 500, intervals)  # all trees are chip trees
    cuFt = linspace(65.44*0.5, 65.44*1.5, intervals)  # select min(35.3147*450/("D_CONBM_kg"/"relNO")), max(35.3147*450/("D_CONBM_kg"/"relNO")), avg(35.3147*450/("D_CONBM_kg"/"relNO")), stddev(35.3147*450/("D_CONBM_kg"/"relNO")) from priority_areas where "relNO">0 and "D_CONBM_kg">0;
    resFrac = 0.8
    slp = linspace(0, 100, intervals)
    ayd = linspace(minAYD, maxAYD, intervals)
    trtArea = linspace(1, 20, intervals)
    elev = [0]
    cols = ['C','D','E','F','H','J']
    prod = pd.DataFrame(list(it.product(slp, ayd, trtArea, elev, tpa, cuFt)), columns = cols)
    prod['A'] = [std_name+str(i) for i in range(len(prod))]
    prod['B'] = 'CA'
    prod.loc[prod['C'] > 40, 'G'] = 'Cable Manual WT'
    prod.loc[prod['C'] < 40, 'G'] = 'Ground-Based Mech WT'
    prod['I'] = resFrac
    prod['K'] = 60 #wood density. 
    return prod


def iterateValues(intervals=65, maxAYD=125, minAYD=80, lmt=None, state='CA',std_name = 'frcs_batch_'):
    """
    Returns a pandas dataframe with the combinatorial
    product of all input variables derived from the input database
    Required some manual work, still can be further automated. 
    """ 
    #tpa = [int(ceil(i[0])) for i in clusterFRCSVariable(queryDB(limit=lmt)['dt_ac'].dropna()).tolist()]
    #cuFt = [i[0] for i in clusterFRCSVariable(queryDB(limit=lmt)['vpt'].dropna()).tolist()]
    tpa =[5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 150, 200, 250, 300, 350, 400]
    cuFt = [1, 2, 5, 7, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
    resFrac = 0.8
    #slp = [i[0] for i in clusterFRCSVariable(queryDB(limit=lmt)['slope'].dropna()).tolist()]
    #slp = [0, 2, 3, 5, 7, 10, 12, 15, 17, 20, 22, 25, 27, 30, 32, 35, 37, 40]
    slp = [41, 42, 45, 47, 50, 52, 55, 60, 65, 70, 75, 80, 85, 90, 95, 99]
    ayd = linspace(minAYD, maxAYD, intervals) #AYD is in feet, not in meters 
    ayd = append(ayd[ayd <= 1300], 500)
    trtArea = [25.0]
    elev = [0]
    cols = ['C','D','E','F','H','J']
    prod = pd.DataFrame(list(it.product(slp, ayd, trtArea, elev, tpa, cuFt)), columns = cols)
    prod['A'] = [std_name+str(i) for i in range(len(prod))]
    prod['B'] = 'CA'
    prod.loc[prod['C'] > 40, 'G'] = 'Cable Manual WT'
    prod.loc[prod['C'] <= 40, 'G'] = 'Ground-Based Mech WT'
    prod['I'] = resFrac
    prod['K'] = 60
        
    
    return prod
 


def batchForFRCS(df, maxRows=10000, sname = sheetName, output='frcs_batch'):
    """
    breaks pandas dataframe into individual Excel files for digestion by FRCS
    """
    files = []
    xapp = xlw.App(visible=False)
    if len(df)/maxRows == 0:
        books = [0]
    else:
        books = range(int(ceil(len(df)/float(maxRows))))
    for b in books:
        path = os.path.join(FRCSDIR,
                            output+str(b)+'.xlsx')
        files.append(path)
        print('writing batch file to {0}'.format(path))
        wb = xlw.Book()
        sht = wb.sheets[0]
        sht.name = sname
        data = df[b*maxRows:(b+1)*maxRows]
        for c in df.columns:
            sht.range(c+'1').options(index=False, header=False).value = colIndex[c]
            sht.range(c+'2').options(index=False, header=False).value = data[c]
        wb.save(path)
        wb.close()
        del sht
        del wb
    print('Done writing files')
    xapp.kill()
    return files


def runFRCS(batchFile, existing = 'append'):
    """
    this function is meant to be multi-processed: one for each frcs_batch file
    """
    #con = sqlite3.connect(os.path.join(FRCSDIR,output))
    #reload(xlw)
    pgEng = dbconfig(user,passwd,dbname, echo_i=True)
    print(pgEng)
    tDir = tf.mkdtemp()
    frcs = os.path.join(tDir,frcsModel) #full path to FRCS in tempfile
    frcsIn = os.path.join(tDir,inputFile) #full path to batch input file
    xapp=xlw.App(visible=False)
    shutil.copy(os.path.join(FRCSDIR,frcsModel),
                tDir)
    
    shutil.copy(batchFile,
                tDir)
    os.rename(batchFile,
              frcsIn)
    frcsObj = xlw.Book(frcs)
    print('created frcs model for run in: %s'%(frcs))
    sys.stdout.flush()
    batchImport = frcsObj.app.macro(batchLoadMacro)
    batchProcess = frcsObj.app.macro(batchPrcMacro)
    batchImport()
    print ('imported batch parameters for %s'%(batchFile))
    sys.stdout.flush()
    batchProcess()
    print( 'processed batch: %s'%(batchFile))
    sys.stdout.flush()
    frcsObj.save()
    frcsObj.close()
    print( 'Closed objects')
    outSheet = pd.read_excel(frcs,
                             sheetname='data')
    outSheet.to_sql('frcs_cost_large',
                    pgEng,
                    schema='frcs',
                    if_exists=existing,
                    index = False)
    print('wrote output to from {0} to database'.format(batchFile))
    sys.stdout.flush()
    shutil.rmtree(tDir)
    xapp.kill()
    print( 'Killed Excel')
    #con.close()
    return outSheet

def queryDB(limit = None):
    eng = dbconfig(user,passwd,dbname)
    sql = 'select "Slope", "AYD", "CT/ac", "ft3/CT", "All Costs, $/GT", "CT Chips, $/GT" from frcs.frcs_cost_large;'
    if limit == None:
        df = pd.read_sql(sql, eng)
    else:
        df = pd.read_sql(sql+' limit {0}'.format(limit), eng)
    return df

def queryDB_test(limit = None):
    eng = dbconfig(user,passwd,dbname)
    sql = 'select "Slope", "AYD", "CT/ac", "ft3/CT", "All Costs, $/GT", "CT Chips, $/GT" from frcs.frcs_cost_test;'
    if limit == None:
        df = pd.read_sql(sql, eng)
    else:
        df = pd.read_sql(sql+' limit {0}'.format(limit), eng)
    return df