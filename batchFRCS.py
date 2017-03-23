# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 11:18:51 2017

@author: pete
"""

import multiprocessing as multi
import cec_utils as ut

runs = ut.iterateVariables(intervals=3)
batchFiles = ut.batchForFRCS(runs)

if __name__ == '__main__':
    pool = multi.Pool()
    pool.map(ut.runFRCS, batchFiles)
    pool.close() 
    pool.join()