from pulp import *

# from https://faculty.washington.edu/toths/Presentations/Lecture%202/Ch11_LPIntro.pdf

# Decision variables
P = LpVariable('Var P', 0, None, LpContinuous)  # number of pallets
L = LpVariable('Var L', 0, None, LpContinuous)  # mbf lumber

# Objective function
prob = LpProblem('Benefit', LpMaximize)
prob += 3*P+10*L, 'Cost'
prob += L <= 200, 'Con1'
prob += P <= 600, 'Con2'
prob += 0.25*P + 1.4*L <= 400, 'Con3'
prob += L >= 0, 'Con4'
prob += P >= 0, 'Con5'
prob.writeLP('lumber.lp')
prob.solve(PULP_CBC_CMD())
