#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Oct  7 18:13:02 2017

@author: jdlara
"""

import cec_utils as ut
import numpy as np 
import pandas as pd 
from sklearn import linear_model
from sklearn.metrics import mean_squared_error, r2_score


frcs = ut.queryDB(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','dgt','cdgy']

# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40 and AYD > 3');

# build matrix A


# use the regresor 
reg = linear_model.LinearRegression()

