#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Oct  7 18:13:02 2017

@author: jdlara
"""

import cec_utils as ut
import numpy as np 
import itertools as it
import pandas as pd 
from scipy import interpolate

#res = ut.queryDB();  

def f(x, y, z):
    return 2 + 4 * x**2 + x**3 + 3 * y**2 - 7 * y**3 + 9*y - z**2 + 10*z**3 
x = np.linspace(1, 4, 11)
y = np.linspace(4, 7, 22)
z = np.linspace(7, 9, 33)
price = f(*np.meshgrid(x, y, z, indexing='ij', sparse=True))
price = np.reshape(price, 11*22*33)

input_data = pd.DataFrame(list(it.product(x, y, z)))

def f0(x, y):
    return np.sin(2*np.pi*x)**2 + np.sin(2*np.pi*y)**2

grid_xn, grid_yn = np.mgrid[0:1:200j, 0:1:200j]
xn = grid_xn[:,0]
yn = grid_yn[0,:]
z0 = f0(grid_xn, grid_yn)

points = np.random.rand(500, 2)
values = f0(points[:, 0], points[:, 1])

f = interpolate.LinearNDInterpolator(points, values, fill_value=0)
zn = f(grid_xn, grid_yn)