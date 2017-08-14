# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 11:18:51 2017

@author: pete
"""

import cec_utils as ut
<<<<<<< HEAD

if __name__ == '__main__':
    runs = ut.iterateValues(intervals=4)
    batchFiles = ut.batchForFRCS(runs,maxRows=1000)
        for b in batchFiles:
            ut.runFRCS(b)
=======
import pandas as pd

if __name__ == '__main__':
    runs = ut.iterateValues(intervals=10)
    runs.to_pickle("Runsfrcs")
    #runs = pd.read_pickle("Runsfrcs")
    print("Runs Done")
    batchFiles = ut.batchForFRCS(runs,maxRows=256)
    print("batchFiles Done")
    for b in batchFiles:
        ut.runFRCS(b)
>>>>>>> 06171b3bc06e9680c83ecf5dca3a0ff792eb993a
#    pool = multi.Pool()
#    pool.map(ut.runFRCS, batchFiles)
#    pool.close() 
#    pool.join()