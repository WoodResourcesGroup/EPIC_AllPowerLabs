#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Deployment model for distributed gasifiers
# Jose Daniel Lara

from __future__ import division
from pyomo.environ import *
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

"""
Load data from files and turn into lists for processing, later this can be updated
directly from the database.

File biomass_v1.dat contains the data from the biomass stocks and their location
All the data is loaded in to a dataframe
File subs_v1.dat contains the data from the electrical nodes and their location
All the data is loaded in to a dataframe
"""

biomass_df = pd.read_csv('biomass_v1.dat', encoding='UTF-8', delimiter=',')
substation_df = pd.read_csv('subs_v2.dat', encoding='UTF-8', delimiter=',')

"""
This portion of the code is somewhat difficult to follow. In the Database the
coordinates Y and X of the sites are independent columns, both the substations
and the biomass. However,from the optimization point of view each "point" is a
single location. So, what it does is that it merges the Y and X coordinates into
a single colum as a string. Later on, this will also be used to generate the
dictionaries with some limits.
"""
biomass_coord = biomass_df.st_y.astype(str).str.cat(biomass_df.st_x.astype(str), sep=',')
biomass_coord = biomass_coord.values.tolist()
substation_coord = substation_df.st_y.astype(str).str.cat(substation_df.st_x.astype(str), sep=',')
substation_coord = substation_coord.values.tolist()

# This portion of the code is temporary, only used to limit the amount of data during development.
biomass_list = biomass_coord  # 32:39]
substation_list = substation_coord[1774:1789]

# Data for the piecewise approximation of installation costs
"""
The data for the piecewise cost of installation is given in # of gasifiers per
substation. This is why the sizes are integers. The cost is the total cost in $
of installing the amount N of gasifiers. Given that the gasifiers can only be
installed in integer number, this is a better approximation of the costs than
using a cost per kw. This explicit calculation needs to be replaced with a file.
"""
number_of_containers = [0, 1, 2, 3, 5, 10]
cost = [0, 4000, 6500, 7500, 9300, 13000]

# Define sets of the substations and biomass stocks and initialize them from data above.
model.SOURCES = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.SUBSTATIONS = Set(initialize=substation_list, doc='Location of Substations')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl: (mdl.SOURCES * mdl.SUBSTATIONS))

"""
Each piecewise approximation requires and independent set for each one of the lines in the approximation. In this case, this is the piecewise approximation for the installations costs, and more maybe required soon.
"""
model.Pw_Install_Cost = Set(initialize=range(1, len(number_of_containers)),
                            doc='Set for the Piecewise approx of the installation cost')

"""
All the parameters are subject to be modified later when doing MonteCarlo simulations
for now, they are fixed during the development stage. This first set of parameters
are not read from the files or database.
"""

# Cost related parameters, most of them to be replaced with cost curves
model.om_cost_fix = Param(initialize=0,
                          doc='Fixed cost of operation per installed kW')
model.om_cost_var = Param(initialize=0,
                          doc='Variable cost of operation per installed kW')
model.transport_cost = Param(initialize=0,
                             doc='Freight in dollars per ton per km')

# Limits related parameters, read from the database/files

biomass_prod = pd.DataFrame(biomass_list)
biomass_prod['production'] = biomass_df.production
biomass_prod = biomass_prod.set_index(0).to_dict()['production']
model.source_biomass_max = Param(model.SOURCES,
                                 initialize=biomass_prod,
                                 doc='Capacity of supply in tons')

# TO BE READ FROM DATABASE IN THE NEAR FUTURE
substation_capacity = pd.DataFrame(substation_list)
substation_capacity['sbs_cap'] = substation_df.limit
substation_capacity = substation_capacity.set_index(0).to_dict()['sbs_cap']
model.max_capacity = Param(model.SUBSTATIONS,
                           initialize=substation_capacity,
                           doc='Max installation per site kW')
model.min_capacity = Param(initialize=150,
                           doc='Min installation per site kW')

biomass_price = pd.DataFrame(biomass_list)
biomass_price['price_trgt'] = 0  # biomass_df.price_trgt
biomass_price = biomass_price.set_index(0).to_dict()['price_trgt']
model.biomass_cost = Param(model.SOURCES,
                           initialize=biomass_price,
                           doc='Cost of biomass per ton')

substation_price = pd.DataFrame(substation_list)
substation_price['sbs_price'] = 0.9  # substation_df.sbs_price'
substation_price = substation_price.set_index(0).to_dict()['sbs_price']
model.fit_tariff = Param(model.SUBSTATIONS,
                         initialize=substation_price,
                         doc='Payment depending on the location $/kWh')

# Operational parameters
model.heat_rate = Param(initialize=833.3, doc='Heat rate kWh/TON')
model.capacity_factor = Param(initialize=0.85, doc='Gasifier capacity factor')
model.total_hours = Param(initialize=8760, doc='Total amount of hours in the analysis period')


"""
Distances from googleAPI, matrx_distance is a dictionary, first it extends
the biomass list to include the substations for the distance calculations
Extract distances and travel times from the google maps API results

As of now, the code checks if the matrices already exist, this protection is
quite unrefined and will need better practices in the future, like comparing the
lists loaded in the model with the list in the files. For testing purposes, it
will work and avoid constant queries to the google API.
"""
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')
distance_table = {}
time_table = {}

if os.path.isfile('distance_table.dat') and os.path.isfile('time_table.dat'):
    print "matrices exist at this time"

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

    for (bio_idx, biomass_source) in enumerate(biomass_list):
        for (sub_idx, substation_dest) in enumerate(substation_list):
            matrx_distance = gmaps.distance_matrix(biomass_coord[bio_idx], substation_coord[sub_idx], mode="driving", departure_time="now", traffic_model="pessimistic")
            error = matrx_distance['rows'][0]['elements'][0]['status']
            if error != 'OK':
                print("Route data unavailable for" + biomass_coord[bio_idx], substation_coord[sub_idx])
            else:
                distance_table[biomass_source, substation_dest] = 0.001 * (matrx_distance['rows'][0]['elements'][0]['distance']['value'])
                time_table[biomass_source, substation_dest] = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])

    f = open('time_table.dat', 'w')
    f.write(str(time_table))
    f.close()

    f = open('distance_table.dat', 'w')
    f.write(str(distance_table))
    f.close()


model.distances = Param(model.ROUTES, initialize=distance_table, doc='Distance in km')
model.times = Param(model.ROUTES, initialize=time_table, doc='Time in Hours')


def calculate_lines(x, y):
    """
    Calculate lines to connect a series of points. This is used for the PW approximations. Given matching vectors of x,y coordinates. This only makes sense for monotolically increasing values.

    This function does not perform a data integrity check.
    """
    slope_list = {}
    intercept_list = {}
    for i in range(0, len(x) - 1):
        slope_list[i + 1] = (y[i] - y[i + 1]) / (x[i] - x[i + 1])
        intercept_list[i + 1] = y[i + 1] - slope_list[i + 1] * x[i + 1]
    return slope_list, intercept_list

install_cost_slope, install_cost_intercept = calculate_lines(number_of_containers, cost)

model.install_cost_slope = Param(model.Pw_Install_Cost, initialize=install_cost_slope, doc='PW c_i')
model.install_cost_intercept = Param(model.Pw_Install_Cost, initialize=install_cost_intercept, doc='PW d_i')

"""
This portion of the code defines the decision making variables, in general the
model will solve for the capacity installed per substation, the decision to
install or not, the amount of biomass transported per route and variable for
the total install cost resulting from the piecewise approximation
"""

model.CapInstalled = Var(model.SUBSTATIONS, within=NonNegativeReals,
                         doc='Installed Capacity kW')
model.InstallorNot = Var(model.SUBSTATIONS, within=Binary,
                         doc='Decision to install or not')
model.BiomassTransported = Var(model.ROUTES, within=NonNegativeReals,
                               doc='Biomass shipment quantities in tons')
model.Fixed_Install_Cost = Var(model.SUBSTATIONS, within=NonNegativeReals,
                               doc='Variable for PW of installation cost')

"""
Define contraints
Here b is the index for sources and s the index for substations
"""


def Subs_Nodal_Balance_rule(mdl, s):
    return mdl.CapInstalled[s] * mdl.capacity_factor * mdl.total_hours == (
        sum(mdl.heat_rate * mdl.BiomassTransported[b, s]
            for b in mdl.SOURCES))

model.Subs_Nodal_Balance = Constraint(model.SUBSTATIONS,
                                      rule=Subs_Nodal_Balance_rule,
                                      doc='Energy Balance at the substation')


def Sources_Nodal_Limit_rule(mdl, b):
    return sum(mdl.BiomassTransported[b, s] for s in model.SUBSTATIONS) <= (
        model.source_biomass_max[b])

model.Sources_Nodal_Limit = Constraint(model.SOURCES,
                                       rule=Sources_Nodal_Limit_rule,
                                       doc='Limit of biomass supply at source')


def Install_Decision_Max_rule(mdl, s):
    return mdl.CapInstalled[s] <= mdl.InstallorNot[s] * mdl.max_capacity[s]

model.Install_Decision_Max = Constraint(
    model.SUBSTATIONS, rule=Install_Decision_Max_rule,
    doc='Limit the maximum installed capacity and bind the continuous decision to the binary InstallorNot variable.')


# This set of constraints define the piece-wise linear approximation of
# installation cost


def Pwapprox_InstallCost_rule(mdl, s, p):
    r"""
    This rule approximates picewise non-linear cost functions.

    It has a input from the output from the function calculate_lines and the set PW. The installation cost is calculated by substation.

    The model is as follows (as per Bersimas Introduction to linear optimization, page 17)

    min z &\\
    s.t. & z \ge c_i x + d_i forall i

    where z is a slack variable, i is the set of lines that approximate the non-linear convex function,
    c_i is the slope of the line, and d_i is the intercept.

    """
    return (mdl.Fixed_Install_Cost[s] >= mdl.install_cost_slope[p] * (mdl.CapInstalled[s] / 150) +
            mdl.install_cost_intercept[p])

model.Installation_Cost = Constraint(model.SUBSTATIONS, model.Pw_Install_Cost,
                                     rule=Pwapprox_InstallCost_rule,
                                     doc='PW constraint')


# Define Objective Function.
def net_profits_rule(mdl):
    return (
        # Fixed capacity installtion costs
        sum(mdl.Fixed_Install_Cost[s] for s in mdl.SUBSTATIONS) -
        # O&M costs (variable & fixed)
        #sum((mdl.om_cost_fix + mdl.capacity_factor * mdl.om_cost_var) * mdl.CapInstalled[s]
        #    for s in mdl.SUBSTATIONS) +
        # Transportation costs
        #sum(mdl.distances[r] * model.BiomassTransported[r]
        #    for r in mdl.ROUTES) +
        # Biomass acquisition costs.
        #sum(mdl.biomass_cost[b] * sum(mdl.BiomassTransported[b, s] for s in mdl.SUBSTATIONS)
        #    for b in mdl.SOURCES) -
        # Gross profits during the period
        sum(mdl.fit_tariff[s] * mdl.CapInstalled[s] * mdl.capacity_factor * mdl.total_hours
            for s in mdl.SUBSTATIONS)
        )

model.net_profits = Objective(rule=net_profits_rule, sense=minimize,
                              doc='Define objective function')

# Display of the output #

# plt.plot(size, cost)
# plt.show()


def pyomo_postprocess(options=None, instance=None, results=None):
    model.CapInstalled.display()
    #model.BiomassTransported.display()

# This is an optional code path that allows the script to be run outside of
# pyomo command-line.  For example:  python transport.py
if __name__ == '__main__':
    # This emulates what the pyomo command-line tools does
    from pyomo.opt import SolverFactory
    import pyomo.environ
    opt = SolverFactory("gurobi")
    results = opt.solve(model, tee=True)
    # sends results to stdout
    results.write()
    print("\nDisplaying Solution\n" + '-' * 60)
    pyomo_postprocess(None, None, results)
