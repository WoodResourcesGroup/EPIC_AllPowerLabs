#!/usr/bin/env python
# -*- coding: utf-8 -*-
#Deployment model for distributed gasifiers
#Jose Daniel Lara

# Import
from pyomo.environ import *
import googlemaps
import datetime
import pprint
# from pprint import pprint # Lets you call it like pprint() instead of pprint.pprint()


# Replace the API key below with a valid API key.
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')

# Creation of a Concrete Model
model = ConcreteModel()

#  Sets
# Read the data for the set definition from files
sources_file = open('sources.dat','r')
destinations_file = open('destinations.dat','r')
substation_list = destinations_file.read().splitlines()
biomass_list = sources_file.read().splitlines()
sources_file.close()
destinations_file.close()

# Components:
#   SETS_ALL_CAPS
#   VarsCamelCase
#   params_lower_case_with_underscores
#   Constraints_Words_Capitalized_With_Underscores
# SET_time_system


## Define sets from the data read##
model.sources = Set(initialize=biomass_list, doc='Location of Biomass sources')
model.substations = Set(initialize=substation_list, doc='Location of Substations')
model.ROUTES = Set(dimen=2, doc='Allows routes from sources to sinks',
                   initialize=lambda mdl: mdl.sources * mdl.substations)
model.time_n = Set(initialize=range(1,25), doc='Time set')

pprint.pprint(model.sources)
model.sources.pprint()

##Define Parameters
# Cost related parameters
model.installation_cost_var = Param(initialize=15, doc='Cost of installing units per kW')
model.installation_cost_fix = Param(initialize=500, doc='Fixed cost of installing the unit')
model.OM_cost_fix = Param(initialize=1, doc='Fixed cost of operation per kW')
model.OM_cost_var = Param(initialize=0.04, doc='Fixed cost of operation per kW')
model.biomass_cost = Param(model.sources, initialize={'Seattle, WA, USA':28,'San Diego, CA, USA':28}, doc='Cost of biomass per ton')
model.transport_cost = Param(initialize=90, doc='Freight in dollars per case per thousand miles')
model.FIT_tariff = Param(model.substations, initialize={'New York, NY, USA':12,'Chicago, IL, USA':14,'Topeka, KY, USA':12}, doc='Payment FIT $/kWh')

#Limits related parameters
model.source_biomass_max = Param(model.sources, initialize={'Seattle, WA, USA':2350,'San Diego, CA, USA':2600}, doc='Capacity of supply in tons')
model.max_power = Param(initialize=1000, doc='Max installation per site kW')
model.min_power = Param(initialize=100, doc='Min installation per site kW')
model.capacity_factor = Param(initialize=0.85, doc='Capacity factor of the gasifier')

#Operational parameters
model.heat_rate = Param(initialize=0.8333, doc='Heat rate of the gasifier kWh/Kg')
model.delta_t=Param(initialize=1, doc='Time step of analysis')
model.total_time=Param(initialize=24, doc='Max timeframe for analysis') #calculate as the max of time_n. Avoid duplicates

#  Distances from googleAPI
matrix_distance = gmaps.distance_matrix(biomass_list, substation_list, mode="driving")
dtab={}
for n in biomass_list:
	k=biomass_list.index(n)
	for nn in substation_list:
		kk=substation_list.index(nn)
		dtab[biomass_list[k],substation_list[kk]]=matrix_distance['rows'][k]['elements'][kk]['distance']['value']
model.distances = Param(model.sources, model.substations,
                        initialize=dtab, doc='Distance in meters')

def c_init(model, b, s):
  return model.transport_cost * model.distances[b,s] / 1000
model.matrix_transport_cost = Param(model.sources, model.substations,
    initialize=c_init, doc='Transport cost in thousands of dollar per case')

model.route_transport_cost = Param(model.ROUTES,
    doc='Transport cost for each route in dollars per ton',
    initialize=lambda mdl, b, s: mdl.transport_cost * mdl.distances[b,s] / 1000)

## Define variables
#Variables

model.P_s_max = Var(model.substations, within=NonNegativeReals, doc='Installed Capacity kW')
model.P_s = Var(model.substations, model.time_n, within=NonNegativeReals, doc='Power generated kW')
model.U_s = Var(model.substations, within=Binary, doc='Decision to install or not')
model.S_b = Var(model.sources, within=NonNegativeReals, doc='Total Biomass supplied from source in tons')
model.flow_biomass = Var(model.sources, model.substations, within=NonNegativeReals, doc='Biomass shipment quantities in tons')

## Define contraints ##
def balance(model):
  return sum(model.P_s[s,t]*model.delta_t for s in model.substations for t in model.time_n) == sum(model.heat_rate*model.S_b[b] for b in model.sources)
model.e_balance = Constraint(rule=balance, doc='Energy Balance in the system')

def capacity_factor_limit(model, substations):
  return sum(model.P_s[s,t]*model.delta_t for s in model.substations for t in model.time_n) <= sum(model.capacity_factor*model.P_s_max[s] for s in model.substations)
model.cap_factor_limit = Constraint(model.substations, rule=capacity_factor_limit, doc='Capacity factor limitation')

def minimum_power(model, s, t):
	return model.min_power*model.U_s[s] <= model.P_s[s,t]
model.minm_power=Constraint(model.substations, model.time_n, rule=minimum_power, doc='Minimum Power constraint')

def maximum_power(model, s, t):
	return model.P_s[s,t] <= model.P_s_max[s]
model.maxm_power=Constraint(model.substations, model.time_n, rule=maximum_power, doc='Max Power constraint')

def maximum_power_limit(model, s):
	return model.P_s_max[s] <= model.U_s[s]*model.max_power
model.maxm_power_limit = Constraint(model.substations, rule=maximum_power_limit, doc='Limit to Max Power')

def maximum_biomass(mdl, b):
	return mdl.S_b[b] <= mdl.source_biomass_max[b]
# model.maxm_biomass = Constraint(model.sources, rule=maximum_biomass, doc='Max biomass in source')
model.maxm_biomass = Constraint(model.sources, doc='Max biomass in source',
    rule=lambda mdl, b: mdl.S_b[b] <= mdl.source_biomass_max[b])

def demand_rule(model, b):
  return sum(model.flow_biomass[b,s] for s in model.substations) == model.S_b[b]
model.demand = Constraint(model.sources, rule=demand_rule, doc='Calculate total supply from biomass source')


## Define Objective and solve ##
def objective_rule(model):
	return (
		sum(model.installation_cost_var*model.P_s_max[s] for s in model.substations) +
		sum(model.installation_cost_fix*model.U_s[s] for s in model.substations) +
		sum(model.OM_cost_fix*model.P_s_max[s] for s in model.substations) +
		sum(model.OM_cost_var*model.P_s[s,t]*model.delta_t for s in model.substations for t in model.time_n) +
		sum(model.matrix_transport_cost[b,s]*model.flow_biomass[b,s] for b in model.sources for s in model.substations) -
		sum(model.biomass_cost[b]*model.S_b[b] for b in model.sources) -
		sum(model.FIT_tariff[s]*model.P_s[s,t]*model.delta_t for s in model.substations for t in model.time_n)
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
