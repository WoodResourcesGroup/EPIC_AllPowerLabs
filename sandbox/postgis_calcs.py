from __future__ import division
from sqlalchemy import create_engine
from pyomo.environ import *
from pyomo.opt import SolverFactory
import googlemaps
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
import ast
# Conventions for naming model components:
#   SETS_ALL_CAPS
#   VarsCamelCase
#   params_pothole_case
#   Constraints_Words_Capitalized_With_Underscores

# Initialize the model
model = ConcreteModel()

engine = create_engine('postgresql+pg8000://jdlara:Amadeus-2010@switch-db2.erg.berkeley.edu:5432/apl_cec?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory')
df_routes = pd.read_sql_query('select biosum.scenario1_gis.lat as source_lat, biosum.scenario1_gis.lon as source_lon, pge_ram.feeders_data.lat as dest_lat, pge_ram.feeders_data.lon as dest_lon, st_distance_Spheroid(biosum.scenario1_gis.st_makepoint, pge_ram.feeders_data.the_geom, \'SPHEROID[\"WGS 84\",6378137,298.257223563]\')/1000 as distance FROM biosum.scenario1_gis, pge_ram.feeders_data where biosum.scenario1_gis.rxcycle = \'1\' and (st_distance_Spheroid(biosum.scenario1_gis.st_makepoint, pge_ram.feeders_data.the_geom, \'SPHEROID[\"WGS 84\",6378137,298.257223563]\')/1000 <= 80);', engine)
print df_routes.count()

"""
This portion of the code is somewhat difficult to follow. In the Database the
coordinates Y and X of the sites are independent columns, both the substations
and the biomass. However,from the optimization point of view each "point" is a
single location. So, what it does is that it merges the Y and X coordinates into
a single colum as a string. Later on, this will also be used to generate the
dictionaries with some limits.
"""

biomass_coord = df_routes.source_lat.astype(str).str.cat(df_routes.source_lon.astype(str), sep=',')
biomass_coord = biomass_coord.values.tolist()
biomass_coord = list(set(biomass_coord))

substation_coord = df_routes.dest_lat.astype(str).str.cat(df_routes.dest_lon.astype(str), sep=',')
substation_coord = substation_coord.values.tolist()
substation_coord = list(set(biomass_coord))

"""
Load data from files and turn into lists for processing, later this can be updated
directly from the database.

File biomass_v1.dat contains the data from the biomass stocks and their location
All the data is loaded in to a dataframe
File subs_v1.dat contains the data from the electrical nodes and their location
All the data is loaded in to a dataframe
"""

#biomass_df = pd.read_csv('biomass_v1.dat', encoding='UTF-8', delimiter=',')
#substation_df = pd.read_csv('subs_v2.dat', encoding='UTF-8', delimiter=',')

"""
The data for the piecewise cost of installation is given in # of gasifiers per
substation. This is why the sizes are integers. The cost is the total cost in $
of installing the amount N of gasifiers. Given that the gasifiers can only be
installed in integer number, this is a better approximation of the costs than
using a cost per kw. This explicit calculation needs to be replaced with a file.
"""
number_of_containers = [0, 1, 2, 3, 5, 10, 20]
cost = [0, 4000, 6500, 7500, 9300, 13000, 17000]

"""
Distances from googleAPI, matrx_distance is a dictionary, first it extends
the biomass list to include the substations for the distance calculations
Extract distances and travel times from the google maps API results

As of now, the code checks if the matrices already exist, this protection is
quite unrefined and will need better practices in the future, like comparing the
lists loaded in the model with the list in the files. For testing purposes, it
will work and avoid constant queries to the google API.

This portion of the code is run before the definition of the sets, to avoid
issues when some routes are not available.
"""
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')
distance_table = {}
time_table = {}
biomass_list = []
substation_list = []

if os.path.isfile('distance_table.dat') and os.path.isfile('substation_list.dat'):
    print "matrices exist at this time"

    f = open('biomass_list.dat', 'r')
    biomass_list = f.read()
    f.close()
    biomass_list = ast.literal_eval(biomass_list)

    f = open('substation_list.dat', 'r')
    substation_list = f.read()
    f.close()
    substation_list = ast.literal_eval(substation_list)

    f = open('time_table.dat', 'r')
    time_table = f.read()
    f.close()
    time_table = ast.literal_eval(time_table)

    f = open('distance_table.dat', 'r')
    distance_table = f.read()
    f.close()
    distance_table = ast.literal_eval(distance_table)

else:
    print "There are no matrix files stored"

    for (bio_idx, biomass_source) in enumerate(biomass_coord):
        for (sub_idx, substation_dest) in enumerate(substation_coord):
            matrx_distance = gmaps.distance_matrix(biomass_coord[bio_idx], substation_coord[sub_idx], mode="driving", departure_time="now", traffic_model="pessimistic")
            error = matrx_distance['rows'][0]['elements'][0]['status']
            if error != 'OK':
                print "Route data unavailable for " + biomass_coord[bio_idx], substation_coord[sub_idx]
            else:
                # print "Route data available for " + biomass_coord[bio_idx], substation_coord[sub_idx]
                if 0.001 * (matrx_distance['rows'][0]['elements'][0]['distance']['value']) > 160:
                    print "Distance too long for " + biomass_coord[bio_idx], substation_coord[sub_idx]
                else:
                    if str(biomass_coord[bio_idx]) not in biomass_list:
                        biomass_list.extend([str(biomass_coord[bio_idx])])
                    if str(substation_coord[sub_idx]) not in substation_list:
                        substation_list.extend([str(substation_coord[sub_idx])])
                    distance_table[biomass_source, substation_dest] = 0.001 * (matrx_distance['rows'][0]['elements'][0]['distance']['value'])
                    time_table[biomass_source, substation_dest] = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])

    f = open('biomass_list.dat', 'w')
    f.write(str(biomass_list))
    f.close()

    f = open('substation_list.dat', 'w')
    f.write(str(substation_list))
    f.close()

    f = open('distance_table.dat', 'w')
    f.write(str(distance_table))
    f.close()

    f = open('time_table.dat', 'w')
    f.write(str(time_table))
    f.close()

# Define sets of the substations and biomass stocks and initialize them from data above.
model.SOURCES = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.SUBSTATIONS = Set(initialize=substation_list, doc='Location of Substations')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl: (mdl.SOURCES * mdl.SUBSTATIONS))
