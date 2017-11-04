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
import multiprocessing
from joblib import Parallel, delayed
import pandas as pd
#import time as tm

def dbconfig(user,passwd,dbname, echo_i=False):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    str1 = ('postgresql+pg8000://' + user +':' + passwd + '@switch-db2.erg.berkeley.edu:5433/' 
            + dbname + '?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory')
    engine = create_engine(str1,echo=echo_i)
    return engine

dbname = 'apl_cec'
user = 'jdlara'
passwd = 'Amadeus-2010'
engine = dbconfig(user, passwd, dbname)
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')

df_routes = pd.read_sql_query('select "PGE".substations.lat as source_lat, "PGE".substations.lon as source_lon, "PGE".substations.subs_no as source_id, "PGE".feeders.lat as dest_lat, "PGE".feeders.lon as dest_lon, "PGE".feeders.feeder_no as dest_id FROM "PGE".feeders, "PGE".substations where st_distance("PGE".substations.geom, "PGE".feeders.geom) < 0.5 limit 10;', engine)

biomass_coord = df_routes.source_lat.astype(str).str.cat(df_routes.source_lon.astype(str), sep=',')
biomass_coord = biomass_coord.values.tolist()
biomass_coord = list(zip(list(set(biomass_coord)),df_routes.source_id.tolist()))

substation_coord = df_routes.dest_lat.astype(str).str.cat(df_routes.dest_lon.astype(str), sep=',')
substation_coord = substation_coord.values.tolist()
substation_coord = list(zip(list(set(substation_coord)),df_routes.dest_id.tolist()))

def matching(source,sink):
    matrx_distance = gmaps.distance_matrix(source[0], sink[0], mode="driving", departure_time="now", traffic_model="pessimistic")
    dbname = 'apl_cec'
    user = 'jdlara'
    passwd = 'Amadeus-2010'
    db_engine = dbconfig(user, passwd, dbname)
    error = matrx_distance['rows'][0]['elements'][0]['status']
    if error != 'OK':
        db_str = ('INSERT INTO frcs.distance_table(source, sink, distance, time) Values(' + source[1] +','+ sink[1] +', -99, -99);')
        db_engine.execute(db_str)
        db_engine.dispose()
    else:
        distance = 0.001 * (matrx_distance['rows'][0]['elements'][0]['distance']['value'])
        time = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])
        db_str = ('INSERT INTO frcs.distance_table(source, sink, distance, time) Values(' + str(source[1]) +','+ str(sink[1]) +','+ str(distance)+','+ str(time)+');') 
        db_engine.execute(db_str)
        db_engine.dispose()
    
Parallel(n_jobs = multiprocessing.cpu_count())(delayed(matching)(source, sink) for source in biomass_coord for sink in substation_coord)

