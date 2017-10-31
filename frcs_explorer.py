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

trace1 = go.Scatter3d(
    x=frcs_1['AYD'].values,
    y=frcs_1['slope'].values,
    z=frcs_1['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color= 'rgba(205, 12, 24, 0.4)', #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)
    
trace2 = go.Scatter3d(
    x=frcs_2['AYD'].values,
    y=frcs_2['slope'].values,
    z=frcs_2['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 0.6)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)    
    
trace3 = go.Scatter3d(
    x=frcs_3['AYD'].values,
    y=frcs_3['slope'].values,
    z=frcs_3['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 0.8)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)
    
trace4 = go.Scatter3d(
    x=frcs_4['AYD'].values,
    y=frcs_4['slope'].values,
    z=frcs_4['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 1)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)     

data = [trace1, trace2, trace3, trace4]
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

##############################################################################
frcs_1= frcs.query('vpt == 10 and tpa == 100 and slope <= 40')
frcs_2= frcs.query('vpt == 30 and tpa == 100 and slope <= 40')
frcs_3= frcs.query('vpt == 50 and tpa == 100 and slope <= 40')
frcs_4= frcs.query('vpt == 80 and tpa == 100 and slope <= 40')

trace1 = go.Scatter3d(
    x=frcs_1['AYD'].values,
    y=frcs_1['slope'].values,
    z=frcs_1['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color= 'rgba(205, 12, 24, 0.4)', #frcs_1['vpt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)
    
trace2 = go.Scatter3d(
    x=frcs_2['AYD'].values,
    y=frcs_2['slope'].values,
    z=frcs_2['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 0.6)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)    
    
trace3 = go.Scatter3d(
    x=frcs_3['AYD'].values,
    y=frcs_3['slope'].values,
    z=frcs_3['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 0.8)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)
    
trace4 = go.Scatter3d(
    x=frcs_4['AYD'].values,
    y=frcs_4['slope'].values,
    z=frcs_4['dgt'].values,
    mode='markers',
    marker=dict(
            
        size=5,
        color='rgba(205, 12, 24, 1)',   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
        opacity=0.8
    )
)     

data = [trace1, trace2, trace3, trace4]
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
    
