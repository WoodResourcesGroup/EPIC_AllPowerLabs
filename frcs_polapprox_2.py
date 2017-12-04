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
from sklearn.metrics import mean_squared_error, mean_absolute_error
from matplotlib import pyplot as plt


frcs = ut.queryDB(limit = None);
frcs_t = ut.queryDB_test(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']
frcs_t.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']

# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope > 40 and cdgy < 100');
frcs_slope40_t = frcs_t.query('slope > 40 and cdgy < 100');

#Model with cross terms 
# build matrix A for case \sum_{i \in predictors} (x_i) + (\sum_{i \in predictors} (x_i))^2
# includes the cross terms in the polynomial or order 2. 

data_train = frcs_slope40
data_test = frcs_slope40_t;
predictors=['slope', 'AYD', 'tpa', 'vpt']
for name1 in ['slope', 'AYD', 'tpa', 'vpt']:
    for name2 in ['slope', 'AYD', 'tpa', 'vpt']:
            colname = (name1+'*'+name2)
            data_train[colname] = frcs_slope40[name1].values*frcs_slope40[name2].values
            data_test[colname] = frcs_slope40_t[name1].values*frcs_slope40_t[name2].values
            predictors.extend([colname])
print(data_train.head())

# use the lasso predictor
# Step 1, define the model type
lasso_2 = linear_model.Lasso(alpha = 0.0001, fit_intercept=True, precompute=True, normalize=True)
# Step 2, fit the model
frcs_lasso_2 = lasso_2.fit(data_train[predictors], data_train['$gt'])
#step 3, use the model with the test data
cost_lasso_2 = frcs_lasso_2.predict(data_test[predictors])

# The mean squared error
print("Mean squared error lasso 2 : %.2f"
      % mean_absolute_error(data_train['$gt'], frcs_lasso_2.predict(data_train[predictors])))
print("Mean squared error lasso 2 over test data: %.2f"
      % mean_squared_error(data_test['$gt'], cost_lasso_2))
print('Coefficients: \n', frcs_lasso_2.coef_)


#use linear predictor
# Step 1, define the model type
linear_2 = linear_model.LinearRegression(normalize=True, fit_intercept=True)
# Step 2, fit the model
frcs_linear_2=linear_2.fit(data_train[predictors], data_train['$gt'])
#step 3, use the model with the test data
cost_linear_2 = frcs_linear_2.predict(data_test[predictors])

# The mean squared error
print("Mean squared error linear 2: %.2f"
      % mean_absolute_error(data_train['$gt'], frcs_linear_2.predict(data_train[predictors])))
print("Mean squared error linear 2 over test data: %.2f"
      % mean_squared_error(data_test['$gt'], cost_linear_2))
print('Coefficients: \n', frcs_linear_2.coef_)

plt.scatter(data_test['AYD'].values, data_test['$gt'].values)
plt.show()

plt.scatter(data_test['AYD'].values, cost_lasso_2)
plt.show()