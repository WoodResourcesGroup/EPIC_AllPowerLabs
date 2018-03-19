#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 10:49:27 2017

@author: jdlara
"""
import cec_utils as ut
import plotly.plotly as py
import plotly.graph_objs as go


frcs = ut.queryDB(limit = None);
frcs.columns = ['slope', 'AYD', 'tpa','vpt','$gt','cdgy']
# Least square implementation for the frcs simulator

#frcs_slope40 = frcs.query('slope <= 40 and tpa == 100');
#frcs_slope80 = frcs.query('slope > 40');

# Plots <= 40%



frcs_vpt1 = go.Mesh3d(
    x=frcs.query('slope <= 40 and tpa == 100 and vpt == 5')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100 and vpt == 5')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100 and vpt == 5')['$gt'].values,
    opacity=0.60, color = '#1F77B4'
)

frcs_vptleg1 = go.Scatter3d(
    x=0,
    y=0,
    z=100,
    opacity=1,
    mode = 'markers',
    marker = dict(color =  '#1F77B4'),
    name = 'tpa == 100 and vpt == 5'
)

frcs_vpt2 = go.Mesh3d(
    x=frcs.query('slope <= 40 and tpa == 100 and vpt == 20')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100 and vpt == 20')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100 and vpt == 20')['$gt'].values,
    opacity=0.60, color = '#FF7F0E'
)

frcs_vptleg2 = go.Scatter3d(
    x=0,
    y=0,
    z=100,
    opacity=1,
    mode = 'markers',
    marker = dict(color =  '#FF7F0E'),
    name = 'tpa == 100 and vpt == 5'
)
    
frcs_vpt3 = go.Mesh3d(
    x=frcs.query('slope <= 40 and tpa == 100 and vpt == 50')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100 and vpt == 50')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100 and vpt == 50')['$gt'].values,
    opacity=0.60, color =   '#2CA02C'
) 

frcs_vptleg3 = go.Scatter3d(
    x=0,
    y=0,
    z=100,
    opacity=1,
    mode = 'markers',
    marker = dict(color =  '#2CA02C'),
    name = 'tpa == 100 and vpt == 50'
)

frcs_vpt4 = go.Mesh3d(
    x=frcs.query('slope <= 40 and tpa == 100 and vpt == 80')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100 and vpt == 80')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100 and vpt == 80')['$gt'].values,
    opacity=0.60, color = '#D62728'
)    

frcs_vptleg4 = go.Scatter3d(
    x=0,
    y=0,
    z=100,
    opacity=1,
    mode = 'markers',
    marker = dict(color =  '#D62728'),
    name = 'tpa == 100 and vpt == 80'
)

frcs_vpt5 = go.Mesh3d(
    x=frcs.query('slope <= 40 and tpa == 100 and vpt == 10')['AYD'].values,
    y=frcs.query('slope <= 40 and tpa == 100 and vpt == 10')['slope'].values,
    z=frcs.query('slope <= 40 and tpa == 100 and vpt == 10')['$gt'].values,
    opacity=0.60, color = '#9467BD'
)    

frcs_vptleg5 = go.Scatter3d(
    x=0,
    y=0,
    z=100,
    opacity=1,
    mode = 'markers',
    marker = dict(color =  '#9467BD'),
    name = 'tpa == 100 and vpt == 10'
)

fig_vpt = [frcs_vpt1, frcs_vptleg1, frcs_vpt5, frcs_vptleg5, frcs_vpt2, frcs_vptleg2, frcs_vpt3,  frcs_vpt4, frcs_vptleg4]
layout = go.Layout(
                    scene = dict(
                    xaxis = dict(
                        title='Yarding \n Distance [ft]'),
                    yaxis = dict(
                        title='slope [%]'),
                    zaxis = dict(
                        title='Cost [$/gt]',
                        range = [0,45])),
                    width=2000,
                    margin=dict(
                    r=20, b=20,
                    l=20, t=20),
                    showlegend=True,
                    legend=dict(orientation="h",
                                font=dict(size=16)
                        )
                     )
    
fig = go.Figure(data=fig_vpt, layout=layout)
py.plot(fig) 
