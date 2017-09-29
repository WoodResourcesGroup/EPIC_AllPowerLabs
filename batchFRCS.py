# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 11:18:51 2017

@author: pete
"""

import cec_utils as ut
#import pandas as pd

if __name__ == '__main__':
    runs = ut.iterateValues(intervals=17)
    runs.to_pickle("Runsfrcs")
    #runs = pd.read_pickle("Runsfrcs")
    print("Runs Done")
    batchFiles = ut.batchForFRCS(runs,maxRows=1326)
    print("batchFiles Done")
    for b in batchFiles:
        out = ut.runFRCS(b)
#    pool = multi.Pool()
#    pool.map(ut.runFRCS, batchFiles)
#    pool.close() 
#    pool.join()