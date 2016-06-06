#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Deployment model for distributed gasifiers
# Jose Daniel Lara

# Import
from __future__ import division
from pyomo.environ import *
import googlemaps
import matplotlib.pyplot as plt

# Replace the API key below with a valid API key.
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')

# Creation of a Concrete Model
model = ConcreteModel()

# Load the data from files
sources_file = open('sources.dat', 'r')
destinations_file = open('destinations.dat', 'r')
substation_list = destinations_file.read().splitlines()
biomass_list = sources_file.read().splitlines()
sources_file.close()
destinations_file.close()

# data for the PW approximation of installation costs
size = [1, 2, 3, 5, 10]
cost = [4000, 6500, 7500, 9300, 13000]

# data for the PW approximation of biomass supply curve

# pending

# Beginning of the optimization model

# Standard for Component definition:
#   SETS_ALL_CAPS
#   VarsCamelCase
#   params_lower_case_with_underscores
#   Constraints_Words_Capitalized_With_Underscores
# SET_time_system

# Define sets from the data read##
model.SOURCES = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.SUBS = Set(initialize=substation_list, doc='Location of Substations')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl: (mdl.SOURCES * mdl.SUBS))
model.PW = Set(initialize=range(1, len(size) + 1), doc='Set for the PW approx')

# Define Parameters
# Cost related parameters

model.installation_cost_var = Param(initialize=150,
                                    doc='Variable installation cost per kW')
model.installation_cost_fix = Param(initialize=5000,
                                    doc='Fixed cost of installing in the site')
model.om_cost_fix = Param(initialize=100,
                          doc='Fixed cost of operation per installed kW')
model.om_cost_var = Param(initialize=40,
                          doc='Variable cost of operation per installed kW')
model.biomass_cost = Param(model.SOURCES,
                           initialize={'Seattle, WA, USA': 12,
                                       'San Diego, CA, USA': 32,
                                       'memphis': 20,
                                       'portland': 22,
                                       'salt-lake-city': 23,
                                       'washington-dc': 25},
                           doc='Cost of biomass per ton')
model.transport_cost = Param(initialize=25,
                             doc='Freight in dollars per ton per km')
model.fit_tariff = Param(model.SUBS,
                         initialize={'New York, NY, USA': 1,
                                     'Chicago, IL, USA': 2.4,
                                     'Topeka, KY, USA': 1.5,
                                     'boston': 1.4,
                                     'dallas': 1.65,
                                     'kansas-cty': 1.65,
                                     'los-angeles': 1.0},
                         doc='Payment FIT $/kWh')

# Limits related parameters
model.source_biomass_max = Param(model.SOURCES,
                                 initialize={'Seattle, WA, USA': 2350,
                                             'San Diego, CA, USA': 2600,
                                             'memphis': 1200,
                                             'portland': 2000,
                                             'salt-lake-city': 2100,
                                             'washington-dc': 2500},
                                 doc='Capacity of supply in tons')
model.max_power = Param(initialize=1000, doc='Max installation per site kW')
model.min_power = Param(initialize=100, doc='Min installation per site kW')


# Operational parameters
model.heat_rate = Param(initialize=0.8333, doc='Heat rate kWh/Kg')
model.capacity_factor = Param(initialize=0.85, doc='Gasifier capacity factor')

#  Distances from googleAPI, matrx_distance is a dictionary, first it extends
# the biomass list to include the substations for the distance calculations
matrx_distance = gmaps.distance_matrix(biomass_list,
                                       substation_list, mode="driving")

# This loop goes over the results from the google API to extract the distances
# the n and k indexes are used to iterate over the contents of the biomass_list
# kk is the same as nn but saving the index in the list.

distance_table = {}
for n in biomass_list:
    k = biomass_list.index(n)
    for nn in substation_list:
        kk = substation_list.index(nn)
        distance_table[biomass_list[k], substation_list[kk]] = 0.001 * (
            matrx_distance['rows'][k]['elements'][kk]['distance']['value'])

model.distances = Param(model.ROUTES,
                        initialize=distance_table, doc='Distance in km')

# This section of the code defines the vectors for the piece wise approximation
# The function to find c and d only works for monotonically increasing function


def slope_calculation(x, y):
    c = []
    d = []
    for i, val_x in enumerate(x):
        if i < len(x) - 1:
            mc = (y[i] - y[i + 1]) / (x[i] - x[i + 1])
            md = y[i + 1] - mc * x[i + 1]
            c.append(mc)
            d.append(md)
            c_dict = dict(zip(range(1, len(x)), c))
            d_dict = dict(zip(range(1, len(x)), d))
    return c_dict, d_dict

c_install_cost, d_install_cost = slope_calculation(size, cost)

model.c_install_cost = Param(model.PW, initialize=c_install_cost, doc='PW c_i')
model.d_install_cost = Param(model.PW, initialize=c_install_cost, doc='PW d_i')

# Define variables
# Generator Variables

model.CapInstalled = Var(model.SUBS, within=NonNegativeReals,
                         doc='Installed Capacity kW')
model.InstallorNot = Var(model.SUBS, within=Binary,
                         doc='Decision to install or not')
model.BiomassTransported = Var(model.ROUTES, within=NonNegativeReals,
                               doc='Biomass shipment quantities in tons')
model.z_i = Var(model.SUBS, within=NonNegativeReals,
                doc='Variable for PW of installation cost')

# Define contraints
# Here b is the index for sources and s the index for substations

# This set of constraints define the energy balances in the system


def Subs_Nodal_Balance(mdl, s):
    return mdl.CapInstalled[s] * mdl.capacity_factor == (
        sum(mdl.heat_rate * mdl.BiomassTransported[b, s]
            for b in mdl.SOURCES))
model.Subs_Nodal_Balance = Constraint(model.SUBS, rule=Subs_Nodal_Balance,
                                      doc='Energy Balance at the substation')


def Sources_Nodal_Limit(mdl, b):
  return sum(mdl.BiomassTransported[b, s] for s in model.SUBS) <= (
      model.source_biomass_max[b])
model.Sources_Nodal_Limit = Constraint(model.SOURCES, rule=Sources_Nodal_Limit,
                                       doc='Limit of biomass supply at source')

# This set of constraints define the limits to the power at the substation


def Install_Decision_Max(mdl, s):
    return mdl.CapInstalled[s] <= mdl.InstallorNot[s] * mdl.max_power
model.Install_Decision_Max = Constraint(model.SUBS, rule=Install_Decision_Max,
                                        doc='Zero or Max Power')


def Install_Decision_Min(mdl, s):
    return mdl.min_power * mdl.InstallorNot[s] <= mdl.CapInstalled[s]
model.Install_Decision_Min = Constraint(model.SUBS, rule=Install_Decision_Min,
                                        doc='Minimum Power constraint')


# This set of constraints define the piece-wise linear approximation of
# installation cost

def Pw_Install_Cost(mdl, s):
    for s in mdl.SUBS:
        for p in mdl.PW:
            return mdl.z_i[s] == (mdl.c_install_cost[p] * mdl.CapInstalled[s] +
                                  mdl.d_install_cost[p])

model.Pw_Install_Cost = Constraint(model.SUBS, rule=Pw_Install_Cost,
                                   doc='PW constraint')


# Define Objective Function.
def objective_rule(mdl):
    return (
        sum(mdl.z_i[s] for s in mdl.SUBS) +
        sum((mdl.om_cost_fix + mdl.capacity_factor * mdl.om_cost_var) * mdl.CapInstalled[s]
            for s in mdl.SUBS) +
        sum((model.om_cost_fix) * mdl.InstallorNot[s]
            for s in mdl.SUBS) +
        sum(mdl.distances[r] * model.BiomassTransported[r]
            for r in mdl.ROUTES) +
        sum(mdl.biomass_cost[b] * sum(mdl.BiomassTransported[b, s] for s in mdl.SUBS)
            for b in mdl.SOURCES) -
        sum(mdl.fit_tariff[s] * mdl.CapInstalled[s] * mdl.capacity_factor * 30 * 24
            for s in mdl.SUBS)
    )

model.objective = Objective(rule=objective_rule, sense=minimize,
                            doc='Define objective function')

# Display of the output #

plt.plot(size, cost)
plt.show()


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
