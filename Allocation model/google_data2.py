#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov  3 17:01:16 2017

@author: jdlara
"""

import googlemaps

from sqlalchemy import create_engine, pool
#from sqlalchemy import Table, Column, String, MetaData
from joblib import Parallel, delayed
import pandas as pd
import os
import warnings
from sqlalchemy import event
from sqlalchemy import exc

def add_engine_pidguard(engine):
    """Add multiprocessing guards.

    Forces a connection to be reconnected if it is detected
    as having been shared to a sub-process.

    """

    @event.listens_for(engine, "connect")
    def connect(dbapi_connection, connection_record):
        connection_record.info['pid'] = os.getpid()

    @event.listens_for(engine, "checkout")
    def checkout(dbapi_connection, connection_record, connection_proxy):
        pid = os.getpid()
        if connection_record.info['pid'] != pid:
            # substitute log.debug() or similar here as desired
            warnings.warn(
                "Parent process %(orig)s forked (%(newproc)s) with an open "
                "database connection, "
                "which is being discarded and recreated." %
                {"newproc": pid, "orig": connection_record.info['pid']})
            connection_record.connection = connection_proxy.connection = None
            raise exc.DisconnectionError(
                "Connection record belongs to pid %s, "
                "attempting to check out in pid %s" %
                (connection_record.info['pid'], pid)
            )

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
    
    eng = create_engine(str1, connect_args={'sslmode':'require'},echo=echo_i, isolation_level="AUTOCOMMIT", poolclass=pool.NullPool)
    return eng

       
def read_db():
    dbname = 'apl_cec'
    user = 'jdlara'
    passwd = 'Amadeus-2010'
    engine2 = dbconfig(user, passwd, dbname)
    add_engine_pidguard(engine2)  
    with engine2.connect() as conn:
        try:
            df_routes = pd.read_sql_query('select  ST_Y(ST_Transform(landing_geom,4326)) as source_lat, ST_X(ST_Transform(landing_geom,4326)) as source_lon, landing_no as source_id, ST_Y(ST_Transform(feeder_geom,4326)) as dest_lat, ST_X(ST_Transform(feeder_geom,4326)) as dest_lon, feeder_no as dest_id FROM lemmav2.substation_routes where api_distance is NULL order by RANDOM() limit 1;', conn)
            biomass_coord = df_routes.source_lat.astype(str).str.cat(df_routes.source_lon.astype(str), sep=',')
            biomass_coord = biomass_coord.values.tolist()
            biomass_coord = list(zip(list(set(biomass_coord)),df_routes.source_id.tolist()))
            
            substation_coord = df_routes.dest_lat.astype(str).str.cat(df_routes.dest_lon.astype(str), sep=',')
            substation_coord = substation_coord.values.tolist()
            substation_coord = list(zip(list(set(substation_coord)),df_routes.dest_id.tolist()))
        except:
            print('db_read_error')
            pass  
    conn.close()
    engine2.dispose()
    
    return biomass_coord,  substation_coord

def matching(biomass_coord, substation_coord):
    gmaps = googlemaps.Client(key='AIzaSyBZgFHHKf7cD3ZmZVHBOpItNImAlYSJ364')
    
    dbname = 'apl_cec'
    user = 'jdlara'
    passwd = 'Amadeus-2010'
    engine = dbconfig(user, passwd, dbname)
    add_engine_pidguard(engine)    
    
    try:        
        matrx_distance = gmaps.distance_matrix(biomass_coord[0][0], substation_coord[0][0], mode="driving", departure_time="now", traffic_model="pessimistic")
        error = matrx_distance['rows'][0]['elements'][0]['status']
        if error != 'OK':
            db_str = ('UPDATE lemmav2.substation_routes set api_distance = -99, api_time = -99 where landing_no =' + str(biomass_coord[0][1]) +' and '+ 'feeder_no =' + str(substation_coord[0][1]) +';') 
        else:
            distance = (matrx_distance['rows'][0]['elements'][0]['distance']['value'])
            try:
                time = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])
            except KeyError:
                time = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration']['value'])
                print("KeyError")
                pass
            db_str = ('UPDATE lemmav2.substation_routes set api_distance =' + str(distance)+','+ 'api_time = '+ str(time) + ' where landing_no =' + str(biomass_coord[0][1]) +' and '+ 'feeder_no =' + str(substation_coord[0][1]) +';') 
    except:
        print('Api error')
        pass
    
    with engine.connect() as conn:
        conn.execute(db_str)
        conn.close()
    engine.dispose()  

def task():
   x, y = read_db()
   #print(x,y)
   matching(x,y)     
   
   
Parallel(n_jobs = 2)(delayed(task)() for i in range(50000))

