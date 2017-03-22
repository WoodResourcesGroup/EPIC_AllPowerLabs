from sqlalchemy import create_engine as ce
import itertools as it
from numpy import linspace, ceil
import pandas as pd
import xlwings as xlw
import tempfile as tf
import shutil, os
import sqlite3

FRCSDIR = 'FRCS'
inputFile = 'FRCS_TestDataOffset.xlsx'
sheetName = 'Input'
frcsModel = "FRCS-West.xls"
batchLoadMacro = "Module1.LoadDataFromXLSX"
batchPrcMacro = "Sheet32.Process_Batch_Click"

dbname = 'apl_cec'
host = 'switch-db2.erg.berkeley.edu'
user = 'ptittmann'

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


def dbconfig(name, echoCmd=True):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    # conString = '//username:{pwd}@{host}:{name}
    engine = ce('postgresql:///{0}'.format(name), echo=echoCmd)
    return engine


def iterateVariables(intervals=20, maxAYD=2500, minAYD=0, state='CA'):
    """
    Returns a pandas dataframe with the combinatorial
    product of all input variables
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
    prod['A'] = ['frcs_batch_'+str(i) for i in range(len(prod))]
    prod['B'] = 'CA'
    prod['G'] = 'Ground-Based Mech WT'
    prod['I'] = resFrac
    prod['K'] = 60
    return prod

def batchForFRCS(df, maxRows=10000, output='frcs_batch'):
    """
    breaks pandas dataframe into individual Excel files for digestion by FRCS
    """
    files = []
    xlw.App(visible=False)
    if len(df)/maxRows == 0:
        books = [0]
    else:
        books = range(int(ceil(len(df)/float(maxRows))))
    for b in books:
        path = os.path.join(FRCSDIR,
                            output+str(b)+'.xlsx')
        files.append(path)
        print 'writing batch file to {0}'.format(path)
        wb = xlw.Book()
        sht = wb.sheets[0]
        sht.name = sheetName
        data = df[b*maxRows:(b+1)*maxRows]
        for c in df.columns:
            sht.range(c+'1').options(index=False, header=False).value = colIndex[c]
            sht.range(c+'2').options(index=False, header=False).value = data[c]
        wb.save(path)
        wb.close()
        del wb
    return files


def runFRCS(batchFile, output='frcs.db'):
    """
    this function is meant to be multi-processed: one for each frcs_batch file
    """
    con = sqlite3.connect(os.path.join(FRCSDIR,output))
    tDir = tf.mkdtemp()
    frcs = os.path.join(tDir,frcsModel) #full path to FRCS in tempfile
    frcsIn = os.path.join(tDir,inputFile) #full path to batch input file
    print frcsIn
    xlw.App(visible=False)
    shutil.copy(os.path.join(FRCSDIR,frcsModel),
                tDir)
    
    shutil.copy(os.path.join(FRCSDIR,batchFile),
                tDir)
    os.rename(os.path.join(tDir,batchFile),
              frcsIn)
    frcsObj = xlw.Book(frcs)
    batchImport = frcsObj.app.macro(batchLoadMacro)
    batchProcess = frcsObj.app.macro(batchPrcMacro)
    batchImport()
    batchProcess()
    frcsObj.save()
    frcsObj.close()
    outSheet = pd.read_excel(frcs,
                             sheetname='data')
    outSheet.to_sql('frcs_cost',
                    con,
                    if_exists='append')
    shutil.rmtree(tDir)