#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Deployment model for distributed gasifiers
# Jose Daniel Lara

from __future__ import division
from pyomo.environ import *
import googlemaps
import numpy as np
import matplotlib.pyplot as plt

# Conventions for naming model components:
#   SETS_ALL_CAPS
#   VarsCamelCase
#   params_pothole_case
#   Constraints_Words_Capitalized_With_Underscores

# Initialize the model
model = ConcreteModel()

# Load data from files and turn into lists for processing, later this can be updated
# directly from the database.

# File biomass_v1.dat contains the data from the biomass stocks and their location
# All the data is loaded in to a dataframe
# File subs_v1.dat contains the data from the electrical nodes and their location
# All the data is loaded in to a dataframe
biomass_df = pd.read_csv('biomass_v1.dat', encoding='UTF-8', delimiter=',')
substation_df = pd.read_csv('subs_v1.dat', encoding='UTF-8', delimiter=',')

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
substation_df = substation_df.st_y.astype(str).str.cat(substation_df.st_x.astype(str), sep=',')
substation_coord = substation_df.values.tolist()

# This portion of the code is temporary, only used to limit the amount of data during
# development.
biomass_list = biomass_coord[0:10]
substation_list = substation_coord[0:10]

# Data for the piecewise approximation of installation costs
"""
The data for the piecewise cost of installation is given in # of gasifiers per
substation. This is why the sizes are integers. The cost is the total cost in $
of installing the amount N of gasifiers. Given that the gasifiers can only be
installed in integer number, this is a better approximation of the costs than
using a cost per kw.
"""
size = [1, 2, 3, 5, 10]
cost = [4000, 6500, 7500, 9300, 13000]

# Define sets of the substations and biomass stocks and initialize them from data above.
model.SOURCES = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.SUBSTATIONS = Set(initialize=substation_list, doc='Location of Substations')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl: (mdl.SOURCES * mdl.SUBSTATIONS))

# Define sets of the piecewise approximations. For now there is only one.
model.Pw_Install_Cost = Set(initialize=range(1, len(size) + 1),
                            doc='Set for the Piecewise approx of the installation cost')

# Define Parameters
"""
All the parameters are subject to be modified later when doing MonteCarlo simulations
for now, they are fixed during the development stage. This first set of parameters
are not read from the files or database.
"""

# Cost related parameters, most of them to be replaced with cost curves
model.installation_cost_var = Param(initialize=150,
                                    doc='Variable installation cost per kW')
model.om_cost_fix = Param(initialize=100,
                          doc='Fixed cost of operation per installed kW')
model.om_cost_var = Param(initialize=40,
                          doc='Variable cost of operation per installed kW')
model.transport_cost = Param(initialize=25,
                             doc='Freight in dollars per ton per km')

# Limits related parameters, read from the database/files

biomass_prod = pd.DataFrame(biomass_list)
biomass_prod['production'] = biomass_df.production
biomass_prod = biomass_prod.set_index(0).to_dict()['production']
model.source_biomass_max = Param(model.SOURCES,
                                 initialize=biomass_prod,
                                 doc='Capacity of supply in tons')

# TO BE READ FROM DATABASE IN THE NEAR FUTURE
model.max_capacity = Param(initialize=1000, doc='Max installation per site kW')

model.min_capacity = Param(initialize=150, doc='Min installation per site kW')

biomass_price = pd.DataFrame(biomass_list)
biomass_price['price_trgt'] = biomass_df.price_trgt
biomass_price = biomass_price.set_index(0).to_dict()['price_trgt']
model.biomass_cost = Param(model.SOURCES,
                           initialize=biomass_price,
                           doc='Cost of biomass per ton')

model.fit_tariff = Param(model.SUBSTATIONS,
                         initialize={'New York, NY, USA': 1,
                                     'Chicago, IL, USA': 2.4,
                                     'Topeka, KY, USA': 1.5,
                                     'boston': 1.4,
                                     'dallas': 1.65,
                                     'kansas-cty': 1.65,
                                     'los-angeles': 1.0},
                         doc='Payment depending on the location $/kWh')

# Operational parameters
model.heat_rate = Param(initialize=0.8333, doc='Heat rate kWh/Kg')
model.capacity_factor = Param(initialize=0.85, doc='Gasifier capacity factor')

#  Distances from googleAPI, matrx_distance is a dictionary, first it extends
# the biomass list to include the substations for the distance calculations
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')
matrx_distance = gmaps.distance_matrix(biomass_list,
                                       substation_list, mode="driving")

# Extract distances and travel times from the google maps API results

distance_table = {}
time_table = {}

for (bio_idx, biomass_source) in enumerate(biomass_list):
    for (sub_idx, substation_dest) in enumerate(substation_list):
        matrx_distance = gmaps.distance_matrix(biomass_coord[bio_idx], substation_coord[sub_idx], mode="driving", departure_time="now", traffic_model="pessimistic")
        distance_table[biomass_source, substation_dest] = 0.001 * (
            matrx_distance['rows'][0]['elements'][0]['distance']['value'])
        time_table[biomass_source, substation_dest] = (1 / 3600) * (matrx_distance['rows'][0]['elements'][0]['duration_in_traffic']['value'])

model.distances = Param(model.ROUTES, initialize=distance_table, doc='Distance in km')
model.times = Param(model.ROUTES, initialize=time_table, doc='Time in Hours')


def calculate_lines(x, y):
    """
    Calculate lines to connect a series of points, given matching vectors
    of x,y coordinates. This only makes sense for monotolically increasing
    values.

    This function does not perform a data integrity check.
    """
    slope_list = {}
    intercept_list = {}
    for i in range(0, len(x) - 1):
        slope_list[i + 1] = (y[i] - y[i + 1]) / (x[i] - x[i + 1])
        intercept_list[i + 1] = y[i + 1] - slope_list[i + 1] * x[i + 1]
    return slope_list, intercept_list

install_cost_slope, install_cost_intercept = calculate_lines(size, cost)

# Add meaningful doc for the components below.
model.install_cost_slope = Param(model.PW, initialize=install_cost_slope, doc='PW c_i')
model.install_cost_intercept = Param(model.PW, initialize=install_cost_intercept, doc='PW d_i')

# Define variables
# Generator Variables

model.CapInstalled = Var(model.SUBSTATIONS, within=NonNegativeReals,
                         doc='Installed Capacity kW')
model.InstallorNot = Var(model.SUBSTATIONS, within=Binary,
                         doc='Decision to install or not')
model.BiomassTransported = Var(model.ROUTES, within=NonNegativeReals,
                               doc='Biomass shipment quantities in tons')
# What is z_i ?
model.z_i = Var(model.SUBSTATIONS, within=NonNegativeReals,
                doc='Variable for PW of installation cost')

# Define contraints
# Here b is the index for sources and s the index for substations

# This set of constraints define the energy balances in the system

# It is confusing & potentially problematic that your function for the
# constraint is named identically to the constraint itself. A standard
# Pyomo convention is to use the suffix "_rule", like Subs_Nodal_Balance_rule.


def Subs_Nodal_Balance(mdl, s):
    # The units don't make sense here unless you include a time duration
    # on the left side
    # Left side: kW * %_cap_factor -> kW
    # Right side: kWh/kg * kg -> kWh
    #   kW != kWh
    return mdl.CapInstalled[s] * mdl.capacity_factor == (
        sum(mdl.heat_rate * mdl.BiomassTransported[b, s]
            for b in mdl.SOURCES))
    # This logic will be buggy if your routes don't connect every biomass
    # sources to every substation. There are multiple ways to address this
    # one of which is to iterate over the list of routes and filter it to
    # suppliers of this substation.
    #       for (b, s2) in mdl.ROUTES if s == s2
    # You could also process the routes in advance and have an indexed set of
    # suppliers for each substation_dest that you could access like so:
    #       for b in mdl.BIOMASS_SUPPLIERS[s]
    # You could also define BiomassTransported[] for every combination of
    # biomass source & substation, then constrain ones that lack routes to be 0.

model.Subs_Nodal_Balance = Constraint(model.SUBSTATIONS, rule=Subs_Nodal_Balance,
                                      doc='Energy Balance at the substation')


def Sources_Nodal_Limit(mdl, b):
    return sum(mdl.BiomassTransported[b, s] for s in model.SUBSTATIONS) <= (
        model.source_biomass_max[b])

# This logic will be buggy if routes don't connect everything. See note above.
model.Sources_Nodal_Limit = Constraint(model.SOURCES, rule=Sources_Nodal_Limit,
                                       doc='Limit of biomass supply at source')

# This set of constraints define the limits to the power at the substation


def Install_Decision_Max(mdl, s):
    return mdl.CapInstalled[s] <= mdl.InstallorNot[s] * mdl.max_capacity
model.Install_Decision_Max = Constraint(
    model.SUBSTATIONS, rule=Install_Decision_Max,
    doc='Limit the maximum installed capacity and bind the continuous decision to the binary InstallorNot variable.')


def Install_Decision_Min(mdl, s):
    return mdl.min_capacity * mdl.InstallorNot[s] <= mdl.CapInstalled[s]
model.Install_Decision_Min = Constraint(model.SUBSTATIONS, rule=Install_Decision_Min,
                                        doc='Installed capacity must exceed the minimum threshold.')


# This set of constraints define the piece-wise linear approximation of
# installation cost

def Pw_Install_Cost(mdl, s):
    # Logic is confusing! You accept substation s as an argument, then
    # ignore that value and iterate over all substations.
    # The for loops below will always return values for the first substation
    # & the first line segment .. calling return inside a loop will exit the loop.
    for s in mdl.SUBSTATIONS:
        for p in mdl.PW:
            return mdl.z_i[s] == (mdl.install_cost_slope[p] * mdl.CapInstalled[s] +
                                  mdl.install_cost_intercept[p])

model.Pw_Install_Cost = Constraint(model.SUBSTATIONS, rule=Pw_Install_Cost,
                                   doc='PW constraint')


# Define Objective Function.
def objective_rule(mdl):
    return (
        # Capacity costs
        sum(mdl.z_i[s] for s in mdl.SUBSTATIONS)
        # O&M costs (variable & fixed)
        + sum((mdl.om_cost_fix + mdl.capacity_factor * mdl.om_cost_var) * mdl.CapInstalled[s]
            for s in mdl.SUBSTATIONS)
        # The next line is buggy; uses same om_cost_fix param as previous line, but
        # units don't cancel out: $/kw-installed * [unitless binary value] != $
        + sum((model.om_cost_fix) * mdl.InstallorNot[s]
            for s in mdl.SUBSTATIONS)
        # Transportation costs
        + sum(mdl.distances[r] * model.BiomassTransported[r]
            for r in mdl.ROUTES)
        # Biomass acquisition costs. These will be buggy if routes aren't the
        # entire cross product. See note in Subs_Nodal_Balance.
        # Why are these costs subtracted instead of added?
        - sum(mdl.biomass_cost[b] * sum(mdl.BiomassTransported[b, s] for s in mdl.SUBSTATIONS)
            for b in mdl.SOURCES)
        # Gross profits (per month?)
        - sum(mdl.fit_tariff[s] * mdl.CapInstalled[s] * mdl.capacity_factor * 30 * 24
            for s in mdl.SUBSTATIONS)
    )

# Rename objective to be more descriptive. Maybe "net_profits"
model.objective = Objective(rule=objective_rule, sense=minimize,
                            doc='Define objective function')

# Display of the output #

# plt.plot(size, cost)
# plt.show()


def pyomo_postprocess(options=None, instance=None, results=None):
    model.CapInstalled.display()
    model.BiomassTransported.display()

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
