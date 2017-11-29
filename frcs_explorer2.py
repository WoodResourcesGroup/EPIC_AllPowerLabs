#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 10:49:27 2017

@author: jdlara
"""
import cec_utils as ut
#import numpy as np 
import plotly.plotly as py
import plotly.graph_objs as go
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt



frcs = ut.queryDB(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','dgt','cdgy']

# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40 and dgt < 100');
frcs_slope80 = frcs.query('slope > 40');


fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
x=frcs_slope40['AYD'].values
y=frcs_slope40['slope'].values
z=frcs_slope40['dgt'].values

ax.scatter(x, y, z, c=frcs_slope40['tpa'].values, marker='o')
plt.show()

# Plots <= 40%

#x=frcs_slope80['AYD'].values
#y=frcs_slope80['slope'].values
#z=frcs_slope80['$gt'].values