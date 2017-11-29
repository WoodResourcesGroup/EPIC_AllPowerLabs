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
# Least square implementation for the frcs simulator

frcs_slope40 = frcs.query('slope <= 40 and tpa == 100');
frcs_slope80 = frcs.query('slope > 40');

# Plots <= 40%

frcs_vpt = go.Scatter3d(
    x=frcs.query('slope <= 40 and tpa == 100')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100')['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs.query('slope <= 40 and tpa == 100')['vpt'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'VPT'),
        opacity=0.8
    )
)

fig_vpt = [frcs_vpt]
layout = go.Layout(
                    scene = dict(
                    xaxis = dict(
                        title='Yarding Distance [ft]'),
                    yaxis = dict(
                        title='slope [%]'),
                    zaxis = dict(
                        title='Cost [$/gt]'),),
                    width=700,
                    margin=dict(
                    r=20, b=10,
                    l=10, t=10)
                  )
    
fig = go.Figure(data=fig_vpt, layout=layout)
py.plot(fig) 

trace2 = go.Scatter3d(
    x=frcs.query('slope <= 40 and vpt == 40')['AYD'].values,
    y=frcs.query('slope <= 40 and vpt == 40')['slope'].values,
    z=frcs.query('slope <= 40 and vpt == 40')['$gt'].values,
    mode='markers',
    marker=dict(
            
        size=3,
        color= frcs.query('slope <= 40 and vpt == 40')['tpa'].values, #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        colorbar=dict(title = 'TPA'),
        opacity=0.8
    )
)

data_slope40 = [trace2]
    
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
    
fig = go.Figure(data=data_slope80, layout=layout)
py.plot(fig) 



