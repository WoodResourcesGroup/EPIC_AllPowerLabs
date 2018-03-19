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



#data files for tpa

#for slope in [5, 20, 35]:
#    for vpt in [5, 40, 80]:
#        str_q = ('slope == ' + str(slope) + ' and AYD == [80.8831168831169, 1015.48051948052, 5766.35064935065] and vpt ==' + str(vpt))
#        frcs.query(str_q).to_csv(('tpa_'+str(slope)+str(vpt)+'.dat'), index=None, sep=' ', mode='w')
            
