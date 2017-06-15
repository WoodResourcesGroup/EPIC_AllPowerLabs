# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 11:18:51 2017

@author: pete
"""

import cec_utils as ut

if __name__ == '__main__':
    runs = ut.iterateValues(intervals=4)
    batchFiles = ut.batchForFRCS(runs,maxRows=1000)
        for b in batchFiles:
            ut.runFRCS(b)
#    pool = multi.Pool()
#    pool.map(ut.runFRCS, batchFiles)
#    pool.close() 
#    pool.join()