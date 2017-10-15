#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 10:49:27 2017

@author: jdlara
"""

import cec_utils as ut
import numpy as np
import plotly.plotly as py
import plotly.graph_objs as go

frcs = ut.queryDB(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','dgt','cdgy']

frcs_tpa50_vpt30 = frcs.query('vpt == 40 and tpa == 50 and AYD > 3')
  
trace1 = go.Scatter3d(
    x=frcs_tpa50_vpt30['AYD'].values,
    y=frcs_tpa50_vpt30['slope'].values,
    z=frcs_tpa50_vpt30['dgt'].values,
    mode='markers',
    marker=dict(
        size=12,
        color=frcs_tpa50_vpt30['dgt'].values,   # set color to an array/list of desired values
        colorscale='Viridis',   # choose a colorscale
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