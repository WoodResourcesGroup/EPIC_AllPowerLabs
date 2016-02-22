#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Import
from pyomo.environ import *
import googlemaps
import datetime
import pprint

# Replace the API key below with a valid API key.
gmaps = googlemaps.Client(key='AIzaSyAh2PIcLDrPecSSR36z2UNubqphdHwIw7M')

# Creation of a Concrete Model TEST
model = ConcreteModel()

## Define sets ##
#  Sets
#       i   canning plants   / seattle, san-diego /
#       j   markets          / new-york, chicago, topeka / ;
sources_file = open('sources.dat','r')
destinations_file = open('destinations.dat','r')
sources = sources_file.read().splitlines()
destinations = destinations_file.read().splitlines()

model.i = Set(initialize=sources, doc='Canning plans')
model.j = Set(initialize=destinations, doc='Markets')

print sources
print destinations

## Define parameters ##
#   Parameters
#       a(i)  capacity of plant i in cases
#         /    seattle     350
#              san-diego   600  /
#       b(j)  demand at market j in cases
#         /    new-york    325
#              chicago     300
#              topeka      275  / ;
model.a = Param(model.i, initialize={'Seattle, WA, USA':350,'San Diego, CA, USA':600}, doc='Capacity of plant i in cases')
model.b = Param(model.j, initialize={'New York, NY, USA':325,'Chicago, IL, USA':300,'Topeka, KY, USA':275}, doc='Demand at market j in cases')
#This table is now calculated directly from the google matrix API
#  Table d(i,j)  distance in thousands of miles
#                    new-york       chicago      topeka
#      seattle          2.5           1.7          1.8
#      san-diego        2.5           1.8          1.4  ;
matrix_distance = gmaps.distance_matrix(sources, destinations, mode="driving")
dtab={}
for n in sources:
	k=sources.index(n)
	for nn in destinations:
		kk=destinations.index(nn)
		dtab[sources[k],destinations[kk]]=matrix_distance['rows'][k]['elements'][kk]['distance']['value']

#pprint.pprint(dtest)
model.d = Param(model.i, model.j, initialize=dtab, doc='Distance in meters')
#  Scalar f  freight in dollars per case per thousand miles  /90/ ;
model.f = Param(initialize=90, doc='Freight in dollars per case per thousand miles')
#  Parameter c(i,j)  transport cost in thousands of dollars per case ;
#            c(i,j) = f * d(i,j) / 1000 ;
def c_init(model, i, j):
  return model.f * model.d[i,j] / 1
model.c = Param(model.i, model.j, initialize=c_init, doc='Transport cost in thousands of dollar per case')

## Define variables ##
#  Variables
#       x(i,j)  shipment quantities in cases
#       z       total transportation costs in thousands of dollars ;
#  Positive Variable x ;
model.x = Var(model.i, model.j, bounds=(0.0,None), doc='Shipment quantities in case')

## Define contrains ##
# supply(i)   observe supply limit at plant i
# supply(i) .. sum (j, x(i,j)) =l= a(i)
def supply_rule(model, i):
  return sum(model.x[i,j] for j in model.j) <= model.a[i]
model.supply = Constraint(model.i, rule=supply_rule, doc='Observe supply limit at plant i')
# demand(j)   satisfy demand at market j ;
# demand(j) .. sum(i, x(i,j)) =g= b(j);
def demand_rule(model, j):
  return sum(model.x[i,j] for i in model.i) >= model.b[j]
model.demand = Constraint(model.j, rule=demand_rule, doc='Satisfy demand at market j')

## Define Objective and solve ##
#  cost        define objective function
#  cost ..        z  =e=  sum((i,j), c(i,j)*x(i,j)) ;
#  Model transport /all/ ;
#  Solve transport using lp minimizing z ;
def objective_rule(model):
  return sum(model.c[i,j]*model.x[i,j] for i in model.i for j in model.j)
model.objective = Objective(rule=objective_rule, sense=minimize, doc='Define objective function')

## Display of the output ##
# Display x.l, x.m ;
def pyomo_postprocess(options=None, instance=None, results=None):
  model.x.display()

# This is an optional code path that allows the script to be run outside of
# pyomo command-line.  For example:  python transport.py
if __name__ == '__main__':
    # This emulates what the pyomo command-line tools does
    from pyomo.opt import SolverFactory
    import pyomo.environ
    opt = SolverFactory("glpk")
    results = opt.solve(model)
    #sends results to stdout
    results.write()
    print("\nDisplaying Solution\n" + '-'*60)
    pyomo_postprocess(None, None, results)
