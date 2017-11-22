#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 17:01:16 2017

@author: jdlara
"""

import googlemaps
from sqlalchemy import create_engine
#from sqlalchemy import Table, Column, String, MetaData
#import numpy as np
#import multiprocessing
from joblib import Parallel, delayed
import pandas as pd
#import time as tm
#import random as rnd

def dbconfig(user,passwd,dbname, echo_i=False):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    #str1 = ('postgresql+pg8000://' + user +':' + passwd + '@switch-db2.erg.berkeley.edu:5433/' 
    #        + dbname + '?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory')
    
    str1 = ('postgresql+psycopg2://'+user+':'+ passwd + '@switch-db2.erg.berkeley.edu:5433/'+dbname) 
    
    engine = create_engine(str1, connect_args={'sslmode':'require'},echo=echo_i)
    return engine

def matching():
    
    gmaps = googlemaps.Client(key='AIzaSyBc1vFDH8sD9J8SKd-A6TbLM1Ny8BSDPfk')    
    dbname = 'apl_cec'
    user = 'jdlara'
    passwd = 'Amadeus-2010'
    db_engine = dbconfig(user, passwd, dbname)
    try:
        df_routes = pd.read_sql_query('select  ST_Y(ST_Transform(landing_geom,4326)) as source_lat, ST_X(ST_Transform(landing_geom,4326)) as source_lon, landing_no as source_id, ST_Y(ST_Transform(feeder_geom,4326)) as dest_lat, ST_X(ST_Transform(feeder_geom,4326)) as dest_lon, feeder_no as dest_id FROM lemmav2.substation_routes where api_distance is NULL order by linear_distance asc limit 1;', db_engine)
    except:
        print('db_read_error')
        pass
        
    biomass_coord = df_routes.source_lat.astype(str).str.cat(df_routes.source_lon.astype(str), sep=',')
    biomass_coord = biomass_coord.values.tolist()
    biomass_coord = list(zip(list(set(biomass_coord)),df_routes.source_id.tolist()))
    
    substation_coord = df_routes.dest_lat.astype(str).str.cat(df_routes.dest_lon.astype(str), sep=',')
    substation_coord = substation_coord.values.tolist()
    substation_coord = list(zip(list(set(substation_coord)),df_routes.dest_id.tolist()))
    
    try:
        matrx_distance = gmaps.distance_matrix(biomass_coord[0][0], substation_coord[0][0], mode="driving", departure_time="now", traffic_model="pessimistic")
    except:
        print('Api error')
        pass

    error = matrx_distance['rows'][0]['elements'][0]['status']
    if error != 'OK':
        try:
            db_str_e = ('UPDATE lemmav2.substation_routes set api_distance = -99, api_time = -99 where landing_no =' + str(biomass_coord[0][1]) +' and '+ 'feeder_no =' + str(substation_coord[0][1]) +';') 
            db_engine.execute(db_str_e)
            db_engine.dispose()
        except:
            print('db_write_error_not_ok')
            pass
    else:
        distance = (matrx_distance['rows'][0]['elements'][0]['distance']['value'])
        try:
            time = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])
        except KeyError:
            time = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration']['value'])
            print("KeyError")
            pass
        db_str = ('UPDATE lemmav2.substation_routes set api_distance =' + str(distance)+','+ 'api_time = '+ str(time) + ' where landing_no =' + str(biomass_coord[0][1]) +' and '+ 'feeder_no =' + str(substation_coord[0][1]) +';') 
        try:
            db_engine.execute(db_str)
            db_engine.dispose()
        except:
            print('db_write_error_ok')
            pass           
    
Parallel(n_jobs = 1)(delayed(matching)() for i in range(1,5))

