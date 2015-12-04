from pyomo.environ import *

model = ConcreteModel()

model.P = Var([0], domain=NonNegativeReals)
model.L = Var([0], domain=NonNegativeReals)

model.OBJ = Objective(expr=3.0 * model.P + 10 * model.L)

model.Constraint1 = Constraint(expr=model.L <= 200)
model.Constraint2 = Constraint(expr=model.P <= 600)
model.Constraint3 = Constraint(expr=0.25*model.P+1.4*model.L <= 400)
