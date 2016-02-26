#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Deployment model for distributed gasifiers
# Jose Daniel Lara

# Import
from __future__ import division
from pyomo.environ import *
import googlemaps
import datetime
from pprint import pprint

# Replace the API key below with a valid API key.
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')

# Creation of a Concrete Model
model = ConcreteModel()

# Load the data from files
sources_file = open('sources.dat', 'r')
destinations_file = open('destinations.dat', 'r')
substation_list = destinations_file.read().splitlines()
exception_list = zip(substation_list, substation_list)
biomass_list = sources_file.read().splitlines()
sources_file.close()
destinations_file.close()

# Components:
#   SETS_ALL_CAPS
#   VarsCamelCase
#   params_lower_case_with_underscores
#   Constraints_Words_Capitalized_With_Underscores
# SET_time_system

# Define sets from the data read##
model.SOURCES = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.SUBS = Set(initialize=substation_list, doc='Location of Substations')
model.EXCEPTION_LIST = Set(initialize=exception_list, doc='Temp Set')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl:
                   ((mdl.SOURCES | mdl.SUBS) * mdl.SUBS) - mdl.EXCEPTION_LIST)
model.TIME_n = Set(initialize=range(1, 25), doc='Time set')

# Define Parameters
# Cost related parameters

model.installation_cost_var = Param(initialize=15,
                                    doc='Variable installation cost per kW')
model.installation_cost_fix = Param(initialize=500,
                                    doc='Fixed cost of installing in the site')
model.om_cost_fix = Param(initialize=1,
                          doc='Fixed cost of operation per installed kW')
model.om_cost_var = Param(initialize=0.04,
                          doc='Variable cost of operation per installed kW')
model.biomass_cost = Param(model.SOURCES,
                           initialize={'Seattle, WA, USA': 28,
                                       'San Diego, CA, USA': 28},
                           doc='Cost of biomass per ton')
model.transport_cost = Param(initialize=90,
                             doc='Freight in dollars per ton per km')
model.fit_tariff = Param(model.SUBS,
                         initialize={'New York, NY, USA': 12,
                                     'Chicago, IL, USA': 14,
                                     'Topeka, KY, USA': 12},
                         doc='Payment FIT $/kWh')

# Limits related parameters
model.source_biomass_max = Param(model.SOURCES,
                                 initialize={'Seattle, WA, USA': 2350,
                                             'San Diego, CA, USA': 2600},
                                 doc='Capacity of supply in tons')
model.installation_cost_var = Param(initialize=150,
                                    doc='Cost of installing units per kW')
model.installation_cost_fix = Param(initialize=5000,
                                    doc='Fixed cost of installing the unit')
model.om_cost_fix = Param(initialize=1, doc='Fixed cost of operation per kW')
model.om_cost_var = Param(initialize=0.04, doc='Fixed operation cost per kW')
model.biomass_cost = Param(model.SOURCES,
                           initialize={'seattle': 28,
                                       'san-diego': 28},
                           doc='Cost of biomass per ton')
model.transport_cost = Param(initialize=90,
                             doc='Freight in dollars per case-thousand-miles')
model.fit_tariff = Param(model.SUBS,
                         initialize={'new-york': 12,
                                     'chicago': 14,
                                     'topeka': 12},
                         doc='Payment FIT $/kWh')
model.max_power = Param(initialize=1000, doc='Max installation per site kW')
model.min_power = Param(initialize=100, doc='Min installation per site kW')
model.capacity_factor = Param(initialize=0.85, doc='Gasifier capacity factor')

# Operational parameters
model.heat_rate = Param(initialize=0.8333, doc='Heat rate kWh/Kg')
model.delta_t = Param(initialize=1, doc='Time step of analysis')
model.total_time = Param(initialize=24, doc='Max timeframe for analysis')


#  Distances from googleAPI, matrx_distance is a dictionary, first it extends
# the biomass list to include the substations for the distance calculations
biomass_list.extend(substation_list)
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
        if n != nn:
            distance_table[biomass_list[k], substation_list[kk]] = (
                matrx_distance['rows'][k]['elements'][kk]['distance']['value'])
model.distances = Param(model.SOURCES, model.SUBS,
                        initialize=distance_table, doc='Distance in meters')

# Define variables
# Generator Variables

model.CapInstalled = Var(model.SUBS, within=NonNegativeReals,
                         doc='Installed Capacity kW')
model.InstallorNot = Var(model.SUBS, within=Binary,
                         doc='Decision to install or not')
model.S_b = Var(model.SOURCES, within=NonNegativeReals, doc='Total Biomass supplied from source')
model.flow_biomass = Var(model.SOURCES, model.SUBS, within=NonNegativeReals, doc='Biomass shipment quantities in tons')

## Define contraints ##
def balance(model):
  return sum(model.P_s[s,t]*model.delta_t for s in model.SUBS for t in model.TIME_n) == sum(model.heat_rate*model.S_b[b] for b in model.SOURCES)
model.e_balance = Constraint(rule=balance, doc='Energy Balance in the system')

def flow_rule(mdl, k):
    inFlow = sum(mdl.flow[i, j] for (i, j) in mdl.routes if j == k)
    outFlow = sum(mdl.flow[i, j] for (i, j) in mdl.routes if i == k)
    return inFlow+mdl.supply[k] == outFlow+mdl.demand[k]
model.flowconstraint = Constraint(model.nodes, rule=flow_rule)

def capacity_factor_limit(model, substations):
  return sum(model.P_s[s,t]*model.delta_t for s in model.SUBS for t in model.TIME_n) <= sum(model.capacity_factor*model.P_s_max[s] for s in model.SUBS)
model.cap_factor_limit = Constraint(model.SUBS, rule=capacity_factor_limit, doc='Capacity factor limitation')

def minimum_power(model, s, t):
	return model.min_power*model.U_s[s] <= model.P_s[s,t]
model.minm_power=Constraint(model.SUBS, model.TIME_n, rule=minimum_power, doc='Minimum Power constraint')

def maximum_power(model, s, t):
	return model.P_s[s,t] <= model.P_s_max[s]
model.maxm_power=Constraint(model.SUBS, model.TIME_n, rule=maximum_power, doc='Max Power constraint')

def maximum_power_limit(model, s):
	return model.P_s_max[s] <= model.U_s[s]*model.max_power
model.maxm_power_limit = Constraint(model.SUBS, rule=maximum_power_limit, doc='Limit to Max Power')

def maximum_biomass(mdl, b):
	return mdl.S_b[b] <= mdl.source_biomass_max[b]
# model.maxm_biomass = Constraint(model.SOURCES, rule=maximum_biomass, doc='Max biomass in source')
model.maxm_biomass = Constraint(model.SOURCES, doc='Max biomass in source',
    rule=lambda mdl, b: mdl.S_b[b] <= mdl.source_biomass_max[b])
=======
model.maxm_power_limit=Constraint(model.SUBS, rule=maximum_power_limit, doc='Limit to Max Power')

def maximum_biomass(model, b):
	return model.S_b[b] <= model.source_biomass_max[b]
model.maxm_biomass=Constraint(model.SOURCES, rule=maximum_biomass, doc='Max biomass in source')

def demand_rule(model, b):
  return sum(model.flow_biomass[b,s] for s in model.SUBS) == model.S_b[b]
model.demand = Constraint(model.SOURCES, rule=demand_rule, doc='Calculate total supply from biomass source')


## Define Objective and solve ##
def objective_rule(model):
	return (
		sum(model.installation_cost_var*model.P_s_max[s] for s in model.SUBS) +
		sum(model.installation_cost_fix*model.U_s[s] for s in model.SUBS) +
		sum(model.OM_cost_fix*model.P_s_max[s] for s in model.SUBS) +
		sum(model.OM_cost_var*model.P_s[s,t]*model.delta_t for s in model.SUBS for t in model.TIME_n) +
		sum(model.matrix_transport_cost[b,s]*model.flow_biomass[b,s] for b in model.SOURCES for s in model.SUBS) -
		sum(model.biomass_cost[b]*model.S_b[b] for b in model.SOURCES) -
		sum(model.FIT_tariff[s]*model.P_s[s,t]*model.delta_t for s in model.SUBS for t in model.TIME_n)
		)
model.objective = Objective(rule=objective_rule, sense=minimize, doc='Define objective function')


## Display of the output ##
# Display x.l, x.m ;
def pyomo_postprocess(options=None, instance=None, results=None):
	model.P_s_max.display()
	model.P_s.display()
	model.U_s.display()
	model.S_b.display()
	model.flow_biomass.display()

# This is an optional code path that allows the script to be run outside of
# pyomo command-line.  For example:  python transport.py
if __name__ == '__main__':
    # This emulates what the pyomo command-line tools does
    from pyomo.opt import SolverFactory
    import pyomo.environ
    opt = SolverFactory("gurobi")
    results = opt.solve(model)
    #sends results to stdout
    results.write()
    print("\nDisplaying Solution\n" + '-'*60)
    pyomo_postprocess(None, None, results)
