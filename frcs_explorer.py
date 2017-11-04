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

frcs = ut.queryDB(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','dgt','cdgy']

#Plots for single TPA and multiple vpt. 

frcs_1= frcs.query('vpt == 10 and tpa == 100 and slope <= 40')
frcs_2= frcs.query('vpt == 30 and tpa == 100 and slope <= 40')
frcs_3= frcs.query('vpt == 50 and tpa == 100 and slope <= 40')
frcs_4= frcs.query('vpt == 80 and tpa == 100 and slope <= 40')

frcs_total_vpt = frcs.query('slope <= 40 and tpa == 100')


trace = go.Scatter3d(
    x=frcs_total_vpt['AYD'].values,
    y=frcs_total_vpt['slope'].values,
    z=frcs_total_vpt['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_total_vpt['vpt'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'VPT'),
        opacity=0.8
    )
)

data_vpt = [trace]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_vpt, layout=layout)
py.plot(fig) 


frcs_total_tpa = frcs.query('slope <= 40 and vpt == 40')


trace = go.Scatter3d(
    x=frcs_total_tpa['AYD'].values,
    y=frcs_total_tpa['slope'].values,
    z=frcs_total_tpa['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_total_tpa['tpa'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'TPA'),
        opacity=0.8
    )
)

data_tpa = [trace]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_tpa, layout=layout)
py.plot(fig) 



