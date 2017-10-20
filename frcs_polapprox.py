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
frcs.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']

# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40');

# build matrix A for case \sum_{i \in predictors} (x_i + x_i^2 + ... + x_i^n)
# no cross terms in the polynomial. Really only n=2 makes much sense. 

data = frcs_slope40
predictors=['slope', 'AYD', 'tpa', 'vpt']
for name in ['slope', 'AYD', 'tpa', 'vpt']:
    for i in range(2,3):  #power of 1 is already there
        colname = (name+'^_%d') %i      #new var will be x_power
        data[colname] = frcs_slope40[name].values**i
        predictors.extend([colname])
print(data.head())


# use the lasso
lasso_1 = linear_model.Lasso(alpha = 0.0001, copy_X=False, fit_intercept=True, precompute=True, normalize=True)
y_pred_lasso_1 = lasso_1.fit(data[predictors], data['$gt'])

#use linear predictor
linear_1 = linear_model.LinearRegression(normalize=True, fit_intercept=True)
y_pred_linear_1=linear_1.fit(data[predictors], data['$gt'])


#Model with cross terms 
# build matrix A for case \sum_{i \in predictors} (x_i) + (\sum_{i \in predictors} (x_i))^2
# includes the cross terms in the polynomial or order 2. 

data = frcs.query('slope <= 40')
predictors=['slope', 'AYD', 'tpa', 'vpt']
for name1 in ['slope', 'AYD', 'tpa', 'vpt']:
    for name2 in ['slope', 'AYD', 'tpa', 'vpt']:
            colname = (name1+'*'+name2)
            data[colname] = frcs_slope40[name1].values*frcs_slope40[name2].values
            predictors.extend([colname])
print(data.head())

# use the lasso
lasso_2 = linear_model.Lasso(alpha = 0.001, copy_X=False, fit_intercept=True, precompute=True, normalize=True)
y_pred_lasso_2 = lasso_2.fit(data[predictors], data['$gt'])

#use linear predictor
linear_2 = linear_model.LinearRegression(normalize=True, fit_intercept=True)
y_pred_linear_2=linear_2.fit(data[predictors], data['$gt'])