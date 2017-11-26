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
frcs.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']
00
# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40');
frcs_slope80 = frcs.query('slope > 40');

# Plots <= 40%

trace1 = go.Scatter3d(
    x=frcs_slope40['AYD'].values,
    y=frcs_slope40['slope'].values,
    z=frcs_slope40['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_slope40['vpt'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'VPT'),
        opacity=0.8
    )
)

data_slope40 = [trace1]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_slope40, layout=layout)
py.plot(fig) 

trace2 = go.Scatter3d(
    x=frcs_slope40['AYD'].values,
    y=frcs_slope40['slope'].values,
    z=frcs_slope40['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_slope40['tpa'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'TPA'),
        opacity=0.8
    )
)

data_slope40 = [trace2]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_slope40, layout=layout)
py.plot(fig) 

# Plots > 40%

trace3 = go.Scatter3d(
    x=frcs_slope80['AYD'].values,
    y=frcs_slope80['slope'].values,
    z=frcs_slope80['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_slope80['vpt'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'VPT'),
        opacity=0.8
    )
)

data_slope80 = [trace1]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_slope80, layout=layout)
py.plot(fig) 

trace2 = go.Scatter3d(
    x=frcs_slope80['AYD'].values,
    y=frcs_slope80['slope'].values,
    z=frcs_slope80['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs_slope80['tpa'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'TPA'),
        opacity=0.8
    )
)

data_slope80 = [trace2]
layout = go.Layout(
    margin=dict(
        l=0,
        r=0,
        b=0,
        t=0
    )
)
    
fig = go.Figure(data=data_slope80, layout=layout)
py.plot(fig) 



