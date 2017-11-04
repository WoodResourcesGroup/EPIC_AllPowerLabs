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
import plotly.plotly as py
import plotly.graph_objs as go


frcs = ut.queryDB(limit = None);
frcs_t = ut.queryDB_test(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']
frcs_t.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']

# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40');
frcs_slope40_t = frcs_t.query('slope <= 40');


# build matrix A for case \sum_{i \in predictors} (x_i + x_i^2 + ... + x_i^n)
# no cross terms in the polynomial. Really only n=2 makes much sense. 

data_train = frcs_slope40
data_test = frcs_slope40_t;
predictors=['slope', 'AYD', 'tpa', 'vpt']
for name in ['slope', 'AYD', 'tpa', 'vpt']:
    for i in range(2,4):  #power of 1 is already there
        colname = (name+'^_%d') %i      #new var will be x_power
        data_train[colname] = frcs_slope40[name].values**i
        data_test[colname] = frcs_slope40_t[name].values**i
        predictors.extend([colname])
print(data_train[predictors].head())


# use the lasso predictor
# Step 1, define the model type
lasso_1 = linear_model.Lasso(alpha = 0.0001, fit_intercept=True, precompute=True, normalize=True)
# Step 2, fit the model
frcs_lasso_1 = lasso_1.fit(data_train[predictors], data_train['$gt'])
#step 3, use the model with the test data
cost_lasso_1 = frcs_lasso_1.predict(data_test[predictors])


# The mean squared error
print("Mean squared error lasso 1: %.2f"
      % mean_absolute_error(data_train['$gt'], frcs_lasso_1.predict(data_train[predictors])))
print("Mean squared error lasso 1 over test data: %.2f"
      % mean_squared_error(data_test['$gt'], cost_lasso_1))
print('Coefficients: \n', frcs_lasso_1.coef_)


#use linear predictor
# Step 1, define the model type
linear_1 = linear_model.LinearRegression(normalize=True, fit_intercept=True)
# Step 2, fit the model
frcs_linear_1=linear_1.fit(data_train[predictors], data_train['$gt'])
#step 3, use the model with the test data
cost_linear_1 = frcs_linear_1.predict(data_test[predictors])

# The mean squared error
print("Mean squared error linear 1 : %.2f"
      % mean_absolute_error(data_train['$gt'], frcs_linear_1.predict(data_train[predictors])))
print("Mean squared error linear 1 over test data: %.2f"
      % mean_squared_error(data_test['$gt'], cost_linear_1))
print('Coefficients: \n', frcs_linear_1.coef_)

########
#Plots section of the code. 

trace1 = go.Scatter3d(
    x=data_test['AYD'].values,
    y=data_test['slope'].values,
    z=data_test['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= data_test['vpt'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Jet',   # choose a colorscale
        opacity=0.8,
        colorbar=dict(title = 'VPT')
    )
)

trace2 = go.Scatter3d(
    x=data_test['AYD'].values,
    y=data_test['slope'].values,
    z=cost_lasso_1,
    mode='markers',
    marker=dict(
            
        size=3,
        color= 'blue', #frcs_1['vpt'].values,   # set color to an array/list of desired values   # choose a colorscale
        opacity=0.8
    )
)

data = [trace1]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)


    
fig = go.Figure(data=data, layout=layout)
py.plot(fig) 
