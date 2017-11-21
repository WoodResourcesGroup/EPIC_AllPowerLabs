#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Nov  5 18:38:59 2017

@author: jdlara
"""

from sqlalchemy import create_engine
#from sqlalchemy import Table, Column, String, MetaData
#import numpy as np
import multiprocessing
from joblib import Parallel, delayed

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

def matching(i):
    dbname = 'apl_cec'
    user = 'jdlara'
    passwd = 'Amadeus-2010'
    db_engine = dbconfig(user, passwd, dbname)
    db_str = ('UPDATE lemmav2.lemma_kmeansclustering SET kmeans_cluster_no = temp.kmeans_cluster_number from (SELECT key, pol_id, ST_ClusterKMeans(geom, (SELECT kmeans_cluster_quantity FROM lemmav2.lemma_dbscancenters_kmeans WHERE lemma_dbscancenters_kmeans.cluster_no ='+ str(i) + ')) OVER () as kmeans_cluster_number from lemmav2.lemma_kmeansclustering where cluster_no = ' + str(i) + ') as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id;')
    #db_str = ('Update lemmav2.lemma_dbscanclusters220 set cluster_no = temp.kmeans_cluster_number from (SELECT key, pol_id, (cluster_no*1000+ST_ClusterKMeans(geom, 10) OVER ()) as kmeans_cluster_number from lemmav2.lemma_dbscanclusters220 where cluster_no = ' + str(i) + ') as temp where lemma_dbscanclusters220.key = temp.key and lemma_dbscanclusters220.pol_id = temp.pol_id;')
    #try: 
    db_engine.execute(db_str)
    db_engine.dispose()
    #except:
    #    print(i)
    #    pass
        
  
dbname = 'apl_cec'
user = 'jdlara'
passwd = 'Amadeus-2010'
db_engine = dbconfig(user, passwd, dbname)
db_str = ('select distinct on(cluster_no) cluster_no from lemmav2.lemma_kmeansclustering where kmeans_cluster_no is null;')
res = db_engine.execute(db_str)
db_engine.dispose()    

Parallel(n_jobs = multiprocessing.cpu_count())(delayed(matching)(row['cluster_no']) for row in res)


   


select key, pol_id, cluster_np from lemma_dbscanclusters220 where lemma_dbscanclusters220.cluster_no in (select cluster_no from lemma_dbscancenters220 where kmeans_cluster_quantity < 1) limit 10;        

;